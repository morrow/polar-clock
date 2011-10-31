#!/usr/bin/env ruby

`coffee -cb *.coffee`
`git add .`
puts "enter commit message: "
message = gets
`git commit -m '#{message}'
git push origin master
git branch -d gh-pages
git branch gh-pages
git push origin gh-pages`
