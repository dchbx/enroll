# frozen_string_literal: true

#http://stackoverflow.com/questions/10811393/how-to-log-user-name-in-rails
module SessionTaggedLogger
  def self.extract_session_id_from_request(req)
    search_for_session = req.env['HTTP_COOKIE'].split(';').map{|k| m = k.match(/_session_id=(.+)/); m && m[1]}
    session_id = search_for_session.compact.try(:first)
    session_id
  rescue StandardError
    'No session'
  end
end