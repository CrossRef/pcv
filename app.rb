require 'sinatra'
require 'mongo'
require 'cgi'

configure do
  conn = Mongo::Connection.new
  crossref = conn['crossref']
  set :citations, crossref['citations']
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

get '/*' do
  if request_doi.empty?
    haml :index
  else
    query = {'to.id' => request_doi}
    docs = settings.citations.find query
    haml :citations, :locals => {:citations => docs, :doi => request_doi}
  end
end

