#!/usr/bin/env python3
"""Build a reproducible shortlist of possible transcription errors in TEI files."""

from __future__ import annotations

import argparse
import csv
import pickle
import re
import tempfile
from collections import Counter, defaultdict
from pathlib import Path

from lxml import etree


TEI = "http://www.tei-c.org/ns/1.0"
NS = {"t": TEI}
XML_ID = "{http://www.w3.org/XML/1998/namespace}id"
XML_LANG = "{http://www.w3.org/XML/1998/namespace}lang"
WORD = re.compile(r"[^\W\d_]{4,}", re.UNICODE)
DUPLICATE = re.compile(r"(?iu)\b([^\W\d_]{2,})\s+\1\b")
FUSED = re.compile(
    r"(?u)\b[A-ZÀ-ÖØ-Þ]?[a-zà-ÿ]{3,}[A-ZÀ-ÖØ-Þ][a-zà-ÿ]{2,}\b"
)
QUESTION_MARK = re.compile(r"(?u)(?:[^\W\d_]\?|\?[^\W\d_])")

LOW_VALUE_DUPLICATES = {
    "amen",
    "de",
    "domini",
    "domino",
    "domina",
    "dominus",
    "en",
    "et",
    "faire",
    "ne",
    "nous",
    "plus",
    "moins",
    "que",
    "se",
    "vous",
}


def corpus_files(data_dir: Path) -> list[Path]:
    return [
        path
        for path in sorted(data_dir.rglob("*.xml"))
        if "cartulaires_index" not in path.parts
    ]


def act_metadata(transcription: etree._Element, path: Path, data_dir: Path) -> dict[str, str]:
    ancestors = transcription.xpath("ancestor::t:text[1]", namespaces=NS)
    act = ancestors[0] if ancestors else None
    pbs = act.xpath(".//t:pb", namespaces=NS) if act is not None else []
    first_pb = pbs[0] if pbs else None
    return {
        "file": path.relative_to(data_dir).as_posix(),
        "act": act.get(XML_ID, "") if act is not None else "",
        "page": first_pb.get("n", "") if first_pb is not None else "",
        "facs": first_pb.get("facs", "") if first_pb is not None else "",
        "lang": transcription.get(XML_LANG, ""),
    }


def context(text: str, start: int, end: int, radius: int = 70) -> str:
    return text[max(0, start - radius) : min(len(text), end + radius)]


def scan_file(path: Path, data_dir: Path) -> dict:
    tree = etree.parse(str(path))
    acts = tree.xpath("//t:text[./t:front and ./t:body]", namespaces=NS)
    transcriptions = tree.xpath("//t:div[@type='transcription']", namespaces=NS)
    stats = {
        "file": path.relative_to(data_dir).as_posix(),
        "acts": len(acts),
        "transcriptions": len(transcriptions),
        "acts_with_facs": sum(
            bool(act.xpath(".//t:pb[@facs]", namespaces=NS)) for act in acts
        ),
        "characters": 0,
    }
    frequencies = {"lat": Counter(), "fro": Counter()}
    examples: dict[tuple[str, str], tuple[str, ...]] = {}
    candidates: list[dict[str, str]] = []

    for transcription in transcriptions:
        metadata = act_metadata(transcription, path, data_dir)
        group = "lat" if metadata["lang"].lower() == "lat" else "fro"
        stats["characters"] += len("".join(transcription.itertext()))

        for node in transcription.xpath(".//text()"):
            parent = node.getparent()
            if not isinstance(parent.tag, str):
                continue
            text = " ".join(str(node).split())
            if not text:
                continue
            in_note = bool(parent.xpath("ancestor-or-self::t:note", namespaces=NS))
            token_group = "fro" if in_note else group
            parent_tag = etree.QName(parent).localname

            for match in WORD.finditer(text):
                word = match.group().casefold()
                frequencies[token_group][word] += 1
                examples.setdefault(
                    (token_group, word),
                    (
                        metadata["file"],
                        metadata["act"],
                        metadata["page"],
                        metadata["facs"],
                        metadata["lang"],
                        parent_tag,
                        context(text, match.start(), match.end()),
                    ),
                )

            for match in FUSED.finditer(text):
                candidates.append(
                    {
                        "type": "fused_word",
                        "confidence": "high",
                        **metadata,
                        "element": parent_tag,
                        "found": match.group(),
                        "suggestion": "",
                        "context": context(text, match.start(), match.end()),
                    }
                )

            for match in QUESTION_MARK.finditer(text):
                candidates.append(
                    {
                        "type": "encoding_question_mark",
                        "confidence": "high",
                        **metadata,
                        "element": parent_tag,
                        "found": match.group(),
                        "suggestion": "",
                        "context": context(text, match.start(), match.end()),
                    }
                )

            if "\ufffd" in text or "\u00c3" in text:
                candidates.append(
                    {
                        "type": "encoding_corruption",
                        "confidence": "high",
                        **metadata,
                        "element": parent_tag,
                        "found": "",
                        "suggestion": "",
                        "context": text[:200],
                    }
                )

            for match in DUPLICATE.finditer(text):
                word = match.group(1)
                candidates.append(
                    {
                        "type": "duplicate_word",
                        "confidence": (
                            "low" if word.casefold() in LOW_VALUE_DUPLICATES else "medium"
                        ),
                        **metadata,
                        "element": parent_tag,
                        "found": match.group(),
                        "suggestion": word,
                        "context": context(text, match.start(), match.end()),
                    }
                )

    return {
        "stats": stats,
        "frequencies": frequencies,
        "examples": examples,
        "candidates": candidates,
    }


def scan_chunk(data_dir: Path, cache_dir: Path, chunk: int, chunks: int) -> None:
    files = corpus_files(data_dir)
    selected = files[chunk::chunks]
    result = [scan_file(path, data_dir) for path in selected]
    cache_dir.mkdir(parents=True, exist_ok=True)
    with (cache_dir / f"chunk-{chunk:02d}.pickle").open("wb") as stream:
        pickle.dump(result, stream, protocol=pickle.HIGHEST_PROTOCOL)
    print(f"chunk {chunk + 1}/{chunks}: {len(selected)} files")


def lexical_candidates(frequencies: dict, examples: dict) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for group, counts in frequencies.items():
        common = {word: count for word, count in counts.items() if count >= 25 and len(word) <= 22}
        substitutions: dict[tuple, list[tuple[str, int]]] = defaultdict(list)
        deleted: dict[str, list[tuple[str, int]]] = defaultdict(list)
        for word, count in common.items():
            for index in range(len(word)):
                substitutions[(len(word), index, word[:index], word[index + 1 :])].append(
                    (word, count)
                )
                deleted[word[:index] + word[index + 1 :]].append((word, count))

        for word, count in counts.items():
            if count > 2 or len(word) > 22:
                continue
            matches: dict[str, int] = {}
            for index in range(len(word)):
                key = (len(word), index, word[:index], word[index + 1 :])
                for candidate, candidate_count in substitutions.get(key, []):
                    if candidate != word:
                        matches[candidate] = max(matches.get(candidate, 0), candidate_count)
            for candidate, candidate_count in deleted.get(word, []):
                matches[candidate] = max(matches.get(candidate, 0), candidate_count)
            for index in range(len(word)):
                shorter = word[:index] + word[index + 1 :]
                if shorter in common:
                    matches[shorter] = common[shorter]
            for index in range(len(word) - 1):
                swapped = word[:index] + word[index + 1] + word[index] + word[index + 2 :]
                if swapped in common and swapped != word:
                    matches[swapped] = common[swapped]
            if not matches:
                continue
            suggestion, suggestion_count = max(matches.items(), key=lambda item: item[1])
            if suggestion_count < 40:
                continue
            file, act, page, facs, lang, element, sample = examples[(group, word)]
            rows.append(
                {
                    "type": "rare_near_common",
                    "confidence": "low",
                    "file": file,
                    "act": act,
                    "page": page,
                    "facs": facs,
                    "lang": lang,
                    "element": element,
                    "found": word,
                    "suggestion": suggestion,
                    "context": sample,
                    "frequency": str(count),
                    "suggestion_frequency": str(suggestion_count),
                }
            )
    return rows


def merge(cache_dir: Path, output: Path) -> None:
    stats = []
    candidates = []
    frequencies = {"lat": Counter(), "fro": Counter()}
    examples = {}
    for cache in sorted(cache_dir.glob("chunk-*.pickle")):
        with cache.open("rb") as stream:
            results = pickle.load(stream)
        for result in results:
            stats.append(result["stats"])
            candidates.extend(result["candidates"])
            for group in frequencies:
                frequencies[group].update(result["frequencies"][group])
            for key, value in result["examples"].items():
                examples.setdefault(key, value)
    candidates.extend(lexical_candidates(frequencies, examples))
    candidates.sort(
        key=lambda row: (
            {"high": 0, "medium": 1, "low": 2}.get(row["confidence"], 3),
            row["file"],
            row["act"],
            row["type"],
        )
    )
    fields = [
        "type",
        "confidence",
        "file",
        "act",
        "page",
        "facs",
        "lang",
        "element",
        "found",
        "suggestion",
        "context",
        "frequency",
        "suggestion_frequency",
    ]
    with output.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(candidates)
    print(
        f"{len(stats)} files, {sum(row['acts'] for row in stats)} acts, "
        f"{sum(row['transcriptions'] for row in stats)} transcriptions, "
        f"{len(candidates)} candidates -> {output}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("scan", "merge"))
    parser.add_argument("--data-dir", type=Path, default=Path(__file__).resolve().parents[1] / "data")
    parser.add_argument(
        "--cache-dir",
        type=Path,
        default=Path(tempfile.gettempdir()) / "cartulaires-transcription-audit",
    )
    parser.add_argument("--chunk", type=int, default=0)
    parser.add_argument("--chunks", type=int, default=6)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.mode == "scan":
        scan_chunk(args.data_dir.resolve(), args.cache_dir, args.chunk, args.chunks)
    else:
        output = args.output or args.data_dir / "audit-transcriptions-candidats.csv"
        merge(args.cache_dir, output)


if __name__ == "__main__":
    main()
