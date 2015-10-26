#!/usr/bin/env python3
# encoding: utf-8
"""
convert_reuters.py

Process Reuters dataset from UCI
http://kdd.ics.uci.edu/databases/reuters21578/reuters21578.html

Created by Wannes Meert on 21-02-2015.
Copyright (c) 2015 KU Leuven. All rights reserved.
"""

import sys
import argparse
import string
import nltk
import os
import glob
from nltk.corpus import stopwords
from nltk.stem.porter import PorterStemmer
from html.parser import HTMLParser
from sklearn.feature_extraction.text import TfidfVectorizer

topics = None
found_topics = set()

class ReutersParser(HTMLParser):
  def __init__(self):
    super().__init__()
    self.articles = []
    self.article = None
    self.tag = ''

  def handle_starttag(self, tag, attr):
    if tag == 'reuters':
      self.article = {
        'title':'',
        'body':'',
        'topics':[]
      }
    if tag == 'd' and (self.tag == 'topics' or self.tag == 'd'):
      self.tag = 'topic'
    else:
      self.tag = tag

  def handle_data(self, data):
    if self.tag == 'body' or self.tag == 'title':
      if not self.article is None:
        self.article[self.tag] += data
    if self.tag == 'topic':
      data = data.strip()
      if len(data) != 0 and data in topics:
        self.article['topics'].append(data)
        global found_topics
        found_topics.add(data)

  def handle_endtag(self, tag):
    if tag == 'reuters':
      if topics is None or len(topics.intersection(self.article['topics'])) > 0:
        self.articles.append(self.article)
      self.article = None


def parse(filename):
  parser = ReutersParser()
  with open(filename, 'r') as ifile:
    try:
      tree = parser.feed(ifile.read())
    except UnicodeDecodeError as err:
      print('ERROR: Unicode decoding failed for {}'.format(filename))
      print(err)
  return parser.articles


stemmer = PorterStemmer()
punct_table = str.maketrans('', '', string.punctuation)


def cleanstring(text):
  lowers = text.lower()
  no_punctuation = lowers.translate(punct_table)
  return no_punctuation


def tokenize(text):
  tokens = nltk.word_tokenize(text)
  stemmed = (stemmer.stem(token) for token in tokens)
  return stemmed

def tfidf(texts, max_features=10):
  tfidf = TfidfVectorizer(tokenizer=tokenize,
                          stop_words='english',
                          max_features=max_features)
  tfs = tfidf.fit_transform(texts)
  tokens = tfidf.get_feature_names()
  return tfs, tokens


def main(argv=None):

  default_input = glob.glob(os.path.join('reuters21578', '*.sgm'))
  default_output = 'reuters_txt'
  problog_facts = 'reuters_facts.pl'
  problog_ev = 'reuters_ev.pl'
  problog_model = 'reuters_model.pl'

  parser = argparse.ArgumentParser(description='Translate Reuters docs to txt')
  parser.add_argument('--verbose', '-v', action='count', help='Verbose output')
  parser.add_argument('--output', '-o', help='Output directory', default=default_output)
  parser.add_argument('--problog', '-p', action='store_true', help='ProbLog file')
  parser.add_argument('--topic', '-t', action='append', help='Keep topic')
  parser.add_argument('--words', '-w', default=10, type=int, help='Number of words to keep')
  parser.add_argument('input', nargs='*', help='List of input files')

  args = parser.parse_args(argv)

  if not os.path.exists(args.output):
    print('Create directory: {}'.format(args.output))
    os.mkdir(args.output)

  if args.topic is not None:
    global topics
    topics = set(args.topic)
    print('Topics: {}'.format(', '.join(args.topic)))

  cur_input = default_input
  if len(args.input) == 0:
    cur_input = default_input
  else:
    cur_input = args.input
  print('Reading: {}'.format(cur_input))

  texts = []
  text_topics = []
  cnt = 1
  for filename in cur_input:
    articles = parse(filename)
    for article in articles:
      text = article['title']+'\n'+article['body']
      new_fn,_ = os.path.splitext(filename)
      new_fn = os.path.join(args.output, os.path.dirname(new_fn))
      new_fn = '{}_{}.txt'.format(new_fn, cnt)
      with open(new_fn, 'w') as ofile:
        ofile.write(text)
      cnt += 1
      text = cleanstring(text)
      texts.append(text)
      text_topics.append(article['topics'])

  tfs, tokens = tfidf(texts, args.words)
  print('words ({}): {}'.format(len(tokens), tokens))
  print('#texts: {}'.format(len(texts)))

  if args.problog:
    with open(problog_facts, 'w') as ofile:
      print('% WORDS', file=ofile)
      cx = tfs.tocoo()
      for i,j,v in zip(cx.row, cx.col, cx.data):
        print('word({},{},{}).'.format(i, tokens[j], v), file=ofile)
      print('\n% TOPICS', file=ofile)
      for idx,article_topics in enumerate(text_topics):
        for topic in article_topics:
          print('query(topic({},{})). % correct.'.format(idx,topic), file=ofile)
        for topic in found_topics.difference(article_topics):
          print('query(topic({},{})). % incorrect.'.format(idx,topic), file=ofile)

    with open(problog_ev, 'w') as ofile:
      print('% WORDS', file=ofile)
      cx = tfs.todense()
      for i in range(cx.shape[0]):
        for j in range(cx.shape[1]):
          v = cx[i,j]
          if v == 0.0:
            print('example(word({},{},{}), false).'.format(i, tokens[j], v), file=ofile)
          else:
            print('example(word({},{},{})).'.format(i, tokens[j], v), file=ofile)

      print('\n% TOPICS', file=ofile)
      for idx,article_topics in enumerate(text_topics):
        for topic in article_topics:
          print('example(topic({},{})).'.format(idx,topic), file=ofile)
        for topic in found_topics.difference(article_topics):
          print('example(topic({},{}),false).'.format(idx,topic), file=ofile)

    with open(problog_model, 'w') as ofile:
      print('% YOUR MODEL', file=ofile)
      for found_topic in found_topics:
        for token in tokens:
          print('t(_)::something({topic},{word}). % TODO'.format(topic=found_topic, word=token), file=ofile)


if __name__ == "__main__":
    sys.exit(main())
