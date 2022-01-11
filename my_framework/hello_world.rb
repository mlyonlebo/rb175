require 'erb'
require_relative 'monroe'
require_relative 'advice'

class HelloWorld < Monroe
  def call(env)
    case env['REQUEST_PATH']
    when '/'
      status = '200'
      headers = {"Content-Type" => 'text/html'}
      response(status, headers) {erb :index }
    when '/advice'
      piece_of_advice = Advice.new.generate
      status = 200
      headers = {"Content-Type" => 'text/html'}
      response(status, headers) {erb :advice, message: piece_of_advice}
    else
      status = '404'
      body = {"Content-Type" => 'text/html', "Content-Length" => '59' }
      response(status, body) {erb :not_found}   
    end
  end
end