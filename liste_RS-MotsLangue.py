#! /usr/bin/env python3
# coding: utf-8
# usage = python nom_script 

"""
Génération du fichier txt qui liste les mots de la langue,
contenus dans les balises <rs>
"""

import os
from os import listdir
from os.path import isfile, join

from bs4 import BeautifulSoup

import re

lst_file = [f for f in listdir("src/") if isfile(join("src/", f))]

motsLangue = dict()

regex = re.compile(r'[\n\r\t\s]+')

for FILE in lst_file:
	if "xml" in FILE:
		file = open("src/"+FILE, "r")

		content = file.read()

		soup = BeautifulSoup(content,features='lxml')
		# récupérer les balises <rs> et leur contenu
		for s in soup.find_all(lambda tag: tag.name.lower()=='rs', {"type":"place"}):
			# <placeName> in <rs> : enlever la balise "placeName" et son contenu 
			for p in s.find_all(lambda tag: tag.name =='placename'):
				p.extract()
			# ne garder que le contenu textuel de la balise <rs>
			s_text = s.get_text()
			s_text = regex.sub(" ", s_text)
			s_text= s_text.strip()
			#créer un dictionnaire des mots de la langue
			if s_text in motsLangue :
				motsLangue[s_text] += 1
			elif s_text != "":
				motsLangue[s_text] = 1
		file.close()

# créer le fichier resultat
baliseRS_MotsLangue = open("baliseRS_MotsLangue.txt", 'w')

for k in sorted(motsLangue.keys()):
	baliseRS_MotsLangue.write("%s: %s\n" % (k, motsLangue[k]))

baliseRS_MotsLangue.close()
		