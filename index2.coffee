#!/usr/bin/env coffee

fs = require "fs"
async = require "async"
loader = require "csv-load-sync"

natural = require "natural"
natural.PorterStemmerEs.attach()
tokenizer = new natural.AggressiveTokenizerEs
stopwords = require("./stopwords.json").stopwords

shuffle = (source) ->
	return source unless source.length >= 2
	for index in [source.length-1..1]
		randomIndex = Math.floor Math.random() * (index + 1)
		[source[index], source[randomIndex]] = [source[randomIndex], source[index]]
	return source

csv = shuffle(loader("#{__dirname}/data2/epn.csv")).map (e)->
	return {
		"message": e.message,
		"topic" : e.kokoro.split(" > ")[0]
		"sentiment" : e.kokoro.split(" > ")[1]
		"tokenized" : (tokenizer.tokenize(e.message).filter (e)-> return stopwords.indexOf(e) is -1).map (e)-> return natural.PorterStemmerEs.stem(e)
	}

trainsize = ~~(csv.length / 3) * 2
data_train  = csv[0..trainsize]
data_test = csv[trainsize..]


console.log "------------------------- Using Regular Data -------------------------"

classifier = new natural.BayesClassifier()
for item in data_train
	classifier.addDocument item.message, item.topic
console.log "training topic Bayes..."
classifier.train()

console.log "testing topic Bayes"
[ok,notok] = [0,0]
for item in data_test
	result = classifier.classify(item.message)
	if result is item.topìc
		ok++
	else
		notok++
console.log "#{(100/(ok+notok))*ok}% Accuracy !"


classifier = new natural.BayesClassifier()
for item in data_train
	classifier.addDocument item.message, item.sentiment
console.log "training sentiment Bayes..."
classifier.train()

console.log "testing sentiment Bayes"
[ok,notok] = [0,0]
for item in data_test
	result = classifier.classify(item.message)
	if result is item.sentiment
		ok++
	else
		notok++
console.log "#{(100/(ok+notok))*ok}% Accuracy !"

console.log "------------------------- Using Stemming -------------------------"


classifier = new natural.BayesClassifier()
for item in data_train
	classifier.addDocument item.tokenized, item.topic
console.log "training topic Bayes..."
classifier.train()

console.log "testing topic Bayes"
[ok,notok] = [0,0]
for item in data_test
	result = classifier.classify(item.tokenized)
	if result is item.topìc
		ok++
	else
		notok++
console.log "#{(100/(ok+notok))*ok}% Accuracy !"


classifier = new natural.BayesClassifier()
for item in data_train
	classifier.addDocument item.tokenized, item.sentiment
console.log "training sentiment Bayes..."
classifier.train()

console.log "testing sentiment Bayes"
[ok,notok] = [0,0]
for item in data_test
	result = classifier.classify(item.tokenized)
	if result is item.sentiment
		ok++
	else
		notok++
console.log "#{(100/(ok+notok))*ok}% Accuracy !"

