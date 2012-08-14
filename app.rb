# -*- coding: utf-8 -*-
require 'sinatra'
require 'mongo'
require 'cgi'
require 'json'

configure do
  conn = Mongo::Connection.new
  crossref = conn['crossref']
  set :citations, crossref['citations']
  set :patents, crossref['patents']
end

helpers do
  def strip_route doi
    doi =~ /^\/(.*?)\/10\./
    doi = $1 ? doi.sub(Regexp.new("^/#{$1}\/"),"") : doi.sub(Regexp.new("^/"),"")
  end

  def request_doi
    doi = request.env['REQUEST_URI']
    doi = strip_route doi
    doi = CGI.unescape(doi)
    doi
  end
end

get '/heartbeat' do
  content_type 'application/json'
  {:status => 'ok'}.to_json
end

get '/*' do
  if request_doi.empty?
    haml :index
  else
    query = {'to.id' => request_doi}
    docs = settings.citations.find query

    # Try to find cambia data for each patent key
    docs = docs.map do |doc|
      doc.merge({'cambia' => settings.patents.find_one({:patent_key => doc['from']['id']})})
    end

    # Remove duplicate patent keys
    docs.uniq! { |doc| doc['cambia']['pub_key'] }

    haml :citations, :locals => {:citations => docs, :doi => request_doi}
  end
end

