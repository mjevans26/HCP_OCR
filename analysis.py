# -*- coding: utf-8 -*-
"""
Created on Wed Aug 25 16:51:04 2021

@author: MEvans
"""
import argparse
import pytesseract
from os import walk, path
from functions import process_file
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('--directory', '-d', required = True, help = 'root directory to look for files for OCR', type = str)
parser.add_argument('--outDir', '-o', required = True, help = 'root directory into which to copy files', type = str)
parser.add_argument('--tessExc', '-t', required = True, help = 'location of tesseract executable', type = str)
args = parser.parse_args()

pytesseract.pytesseract.tesseract_cmd = f'{args.t}'

from pdf2image.exceptions import (
    PDFInfoNotInstalledError,
    PDFPageCountError,
    PDFSyntaxError
)

rows = []
for root, dirs, files in walk(args.d):
  if len(files) > 0:
    for file in files:
      if path.splitext(file)[1] == '.pdf':
        row = process_file(root, file, args.o)
        rows.append(row)

df = pd.DataFrame(rows, columns = ['file', 'region', 'hcp', 'npages', 'ocr'])
df.to_csv(f'{args.o}/metadata.csv')