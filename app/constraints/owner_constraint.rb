# Route constraint that hides a mounted engine (404) from everyone but owners.
class OwnerConstraint
  def matches?(request)
    session_id = request.cookie_jar.signed[:session_id]
    user = Session.find_by(id: session_id)&.user if session_id
    user&.can_manage? || false
  end
end
