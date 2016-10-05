#!/usr/bin/env coffee

srt = require "srt"
fs = require "fs"
async = require "async"

async.waterfall [
	(cb)->
		# let's get the files to process
		allfiles = []
		fs.readdir "#{__dirname}/data", (err1,folderlist)->
			async.each folderlist,(folder,cb2)->
				fs.readdir "#{__dirname}/data/#{folder}", (err2,filelist)->
					if !err2?
						allfiles = allfiles.concat filelist.map (e)-> "#{__dirname}/data/#{folder}/#{e}"
					cb2()
			,->
				cb(null,allfiles)
	,(filelist,cb)->
		# process the files into one large text and split by participation blocks
		alltext = ""
		async.eachSeries filelist, (filename,cb2)->
			srt filename, (err3,data)->
				for k,v of data
					alltext += " #{v.text.toLowerCase()}"
				cb2(null)
		,(err2)->
			alltext = alltext.replace /\n/gi, " "
			alltext = alltext.split("tiene la palabra").join("|").split("participación de").join("|").split("|")
			cb(null,alltext)
	,(text,cb)->
		#finding the block attribution
		posibles = require "./posibles.json"
		#console.log text, text.length
		lastmatched = null
		for bloque in text
			match = null
			for k,v of posibles
				for item in v.nombres
					if bloque[0..100].indexOf(item) isnt -1
						match = k
						break
			lastmatched = match if match?
			#console.log lastmatched, bloque[0..100]
			if lastmatched?
				posibles[lastmatched].participaciones ?= ""
				posibles[lastmatched].participaciones += " #{bloque}"
		cb(null,posibles)
	,(clastext, cb)->
		# word aggregation
		natural = require "natural"
		tokenizer = new natural.AggressiveTokenizerEs;
		stopwords = require("./stopwords.json").stopwords

		max_len = 3
		for k,v of clastext
			clastext[k].wordcloud ?= {}
			arrayOfwords = tokenizer.tokenize(v.participaciones)
			phrases = {}
			for e,ix in arrayOfwords
				[comb,comb2] = [null,null]
				# if stopwords.indexOf(e) is -1
				# 	phrases[e] ?= 0
				# 	phrases[e]++
				comb = "#{e}_#{arrayOfwords[ix+1]}" if arrayOfwords[ix+1]?
				if arrayOfwords[ix+1]? and (stopwords.indexOf(e) is -1 or stopwords.indexOf(arrayOfwords[ix+1]) is -1)
					phrases[comb] ?= 0
					phrases[comb]++
				if arrayOfwords[ix+2]? and (stopwords.indexOf(e) is -1 or stopwords.indexOf(arrayOfwords[ix+1]) is -1 or stopwords.indexOf(arrayOfwords[ix+2]) is -1)
					comb2 = "#{comb}_#{arrayOfwords[ix+2]}"
					phrases[comb2] ?= 0
					phrases[comb2]++
			for phrase, times of phrases
				clastext[k].wordcloud[phrase] = times if times > 5
		cb(null,clastext)
	,(clastext, cb)->
		#remove words in words
		for k,v of clastext
			for word,times of v.wordcloud
				for word2,times2 of v.wordcloud
					if word isnt word2 and word2.split("_").indexOf(word) isnt -1
						#console.log "#{word} is contained in #{word2}, #{times}, #{times2}"
						delete clastext[k].wordcloud[word] if (times/times2) <=2
			#console.log k,clastext[k].wordcloud
		cb(null,clastext)
	,(clastext,cb)->
		#export to datafile
		datafile = {}
		for k,v of clastext
			datafile[k] = []
			for word,times of v.wordcloud
				datafile[k].push [(word.replace /\_/gi," "),times]
		fs.writeFile "#{__dirname}/html/data.js", "data=#{JSON.stringify(datafile)}", (errwrite)->
			cb(null)
], (err,result)->
	throw err if err?
	process.exit 0


#srt(fileName, "en", function (err, data) {