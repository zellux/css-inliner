# Transform HTML+CSS to a single HTML file with inlined CSS

require 'css_parser'
require 'nokogiri'
include CssParser

def specificity(sel)
  elmt = sel.scan(/^\w+| \w+/).size
  cls = sel.scan(/\.\w+/).size
  id = sel.scan(/#\w+/).size
  [0, id, cls, elmt]
end

selectors = []
parser = CssParser::Parser.new
parser.load_file!('style.css')
parser.each_selector {|s, decl, spec| selectors << [s, decl, spec] }

selectors = selectors.sort_by.with_index {|x, i| [x[2], i] }
doc = Nokogiri::HTML(File.open("origin.html"))

css = {}
selectors.each do |s, decl, spec|
  puts "#{s}: {#{decl} #{specificity(s)}}"
  doc.css(s).each do |node|
    decl.split(';').each do |rule|
      property, value = rule.scan(/(\S+):\s*(\S+)/)[0]
      css[node] ||= {}
      css[node][property] = value
    end
  end
end

css.each do |node, properties|
  style = properties.collect {|k,v| "#{k}: #{v}; " }.join('')
  node['style'] = "#{style}"
end

# Remove css link
doc.xpath('//html/head/link').remove

File.open('output.html', 'w').write doc.to_html

