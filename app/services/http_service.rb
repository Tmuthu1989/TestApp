class HttpService
  attr_accessor :uri
  def initialize(uri)
    self.uri = uri
  end

  def post(body={}, cookie=nil)
    headers = {"Content-Type" => "application/json"}
    headers[:cookie] = cookie if cookie
    HTTParty.post(uri, {body: body.to_json, headers: headers})
  end

  def get(query={}, headers={})
    HTTParty.get(uri, {query: query, headers: headers})
  end

  def post_multi_part(body={})
    headers = {"Content-Type" => "multipart/form-data"}
    HTTParty.post(uri, {body: body, headers: headers})
  end

end
