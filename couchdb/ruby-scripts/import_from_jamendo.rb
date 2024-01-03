require 'nokogiri'
require 'couchrest'

class JamendoCallbacks < Nokogiri::XML::SAX::Document
  def initialize
    @db = CouchRest.database!("http://admin:couchdb@localhost:5984/music")
    @count = 0
    @stack = []
    @artist = nil
    @album = nil
    @track = nil
    @tag = nil
    @buffer = nil
  end

  def start_element(name, attrs = [])
    case name
    when 'artist'
      @artist = { :albums => [] }
      @stack.push @artist
    when 'album'
      @album = { :tracks => [] }
      @artist[:albums].push @album
      @stack.push @album
    when 'track'
      @track = { :tags => [] }
      @album[:tracks].push @track
      @stack.push @track
    when 'tag'
      @tag = {}
      @track[:tags].push @tag
      @stack.push @tag
    when 'Artists', 'Albums', 'Tracks', 'Tags'
      # Ignore
    else
      @buffer = []
    end
  end

  def characters(string)
    @buffer << string unless @buffer.nil?
  end

  def end_element(name)
    case name
    when 'artist'
      @stack.pop
      @artist['_id'] = @artist['id']
      @artist[:random] = rand
      @db.save_doc(@artist, false, true)
      @count += 1
      puts " #{@count} records inserted!" if @count % 500 == 0
    when 'album', 'track', 'tag'
      top = @stack.pop
      top[:random] = rand
    when 'Artists', 'Albums', 'Tracks', 'Tags'
      # Ignore
    else
      if @stack[-1] && @buffer
        @stack[-1][name] = @buffer.join.force_encoding('utf-8')
        @buffer = nil
      end
    end
  end
end

parser = Nokogiri::XML::SAX::Parser.new(JamendoCallbacks.new)
parser.parse(ARGF)
