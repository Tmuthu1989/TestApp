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

  def post_multi_part(body={}, cookie=nil)
    headers = {"Content-Type" => "multipart/form-data", "access_token" => "access_token_d960dd6ee060364553c816abe6d8b1719ae31a09"}
    headers[:cookie] = cookie if cookie
    HTTParty.post(uri, {body: body, headers: headers})
  end

end
