# Authentication Service - Handles bearer token authentication
class AuthenticationService
  def self.authenticate(token)
    return false if token.blank?

    # Remove 'Bearer ' prefix if present
    clean_token = token.gsub(/^Bearer\s+/i, "")

    # Find valid token
    auth_token = AuthenticationToken.valid.find_by(token: clean_token)
    return false unless auth_token

    # Check if token is still valid
    return false unless auth_token.still_valid?

    true
  end

  def self.generate_token
    AuthenticationToken.generate
  end

  def self.extract_token_from_header(auth_header)
    return nil if auth_header.blank?

    # Extract token from "Bearer <token>" format
    match = auth_header.match(/^Bearer\s+(.+)$/i)
    match ? match[1] : nil
  end
end
