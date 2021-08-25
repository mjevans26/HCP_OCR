# -*- coding: utf-8 -*-
"""
Created on Wed Aug 25 16:47:29 2021

@author: MEvans
"""

import PyPDF2 
from pytesseract import image_to_string
import cv2
import os
from os import path
import numpy as np
from pdf2image import convert_from_path
from os.path import join
from shutil import copyfile

def check_file(file):
  """Get the number of pages in a PDF and check if text is OCR'd
  Parameters:
    file (str): path to file
  Return:
    tpl (int, bool): number of pages, does the first page of file contain text?
  """   
  # creating a pdf file object 
  pdfFileObj = open(file, 'rb') 
      
  # creating a pdf reader object 
  pdfReader = PyPDF2.PdfFileReader(pdfFileObj) 
      
  # printing number of pages in pdf file 
  if not pdfReader.isEncrypted:
    npages = pdfReader.numPages 
    print(file, 'contained', npages, 'pages')

    # creating a page object 
    pageObj = pdfReader.getPage(0) 

    text = pageObj.extractText()

    hasText = len(text) > 0

  else:
    hasText = True
    npages = 0

  # close the pdf file object 
  pdfFileObj.close()   

  return npages, hasText

def ocr_file(file, out, preprocess = 'thresh'):
  # get the basename of the image
  base = path.splitext(path.basename(file))[0]
  print('file basename', base)
  # we have pdfs coming in, so need to convert to image file that is interpretable by opencv
  pages = convert_from_path(file)
  # npages = len(pages)
  # print('number of pages = ', npages)

  output = ''
  for page in pages:

      # process the image
      #image = cv2.imread(args.image) # we don't have to read image, pdf2image creates a list of PIL images
      # PIL images aren't necessarily in the format needed by cv, which is a BGR numpy array
      array = np.array(page)
      print('shape of current page array', array.shape)
      gray = cv2.cvtColor(array, cv2.COLOR_RGB2GRAY)
      #bgr = page.convert('RGB')
      #gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)

      if preprocess == 'thresh':
          gray = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY)[1]

      elif preprocess == 'blur':
          gray = cv2.medianBlur(gray, 3)

      #filename = f'{os.getpid()}.png'
      #cv2.imwrite(filename, gray)

      text = image_to_string(gray)
          #os.remove(filename)
      output = output + text

  with open(f'{out}/{base}.txt', 'w') as f:
      f.write(output)
      
def process_file(root, file, out):
    infile = join(root, file)
    parts = root.split('/')
    region = parts[-4]
    hcp = parts[-3]
    outpath = join(out, '/'.join(parts[9:12]))
    outfile = join(outpath, file)
    
    os.makedirs(outpath, exist_ok = True)
    
    # check_file takes full filepath and returns num pages and whether text was extracted
    npages, hasText = check_file(infile)
    # if text was extracted copy the original file over to our
    if hasText:
        print('copying', infile, 'to', outfile)
        copyfile(infile, outfile)# do something
        ocr = 'Yes'
    else:
        print('ocr-ing', outfile)
        ocr_file(infile, outpath)
        ocr = 'No'
      
    row = [file, region, hcp, npages, ocr]
    return row     