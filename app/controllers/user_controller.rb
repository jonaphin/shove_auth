class UserController < ApplicationController
  before_filter :check_username, :except=>[:create]
  
  def create
    @username = params[:id]
    return fail_403 unless @username
    result = verify_hmac("POST /user/#{@username} %s")
    return false unless result
    
    @user = Account.find_by_username @username
    if @user
      render :text=>'405 Method Not Allowed', :status=>405
      return false
    end
    
    @account = Account.new(:username=>@username)
    respond_to do |format|
      if @account.save
        format.xml  { head :created }
        format.json { head :created }
      else
        format.xml  { render :xml => @account.errors, :status => :unprocessable_entity }
        format.json { render :json=> @account.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    password = params[:password]
    result = verify_hmac("PUT /user/#{@username} %s #{password}")
    return false unless result
    
    @user.password = password
    @user.save
    
    respond_to do |wants|
      wants.xml { head :ok }
      wants.json { head :ok }
    end
  end

  def show
    result = verify_hmac("GET /user/#{@username} %s")
    return false unless result
    
    respond_to do |wants|
      wants.xml {  render :xml=>@user.to_xml }
      wants.json { render :json=>@user.to_json }
    end
  end

  def destroy
  end
  
  private
  def verify_hmac(content)
    sid = params[:session][:sid]
    verifier = sprintf(content, sid)
    hmac = params[:session][:hmac]
    session_secret = Nonce.find_by_sid(sid).session_secret
    
    check = Nonce.hmac(session_secret, verifier)
    return true if check == hmac
    
    return fail_403
  rescue
    return fail_403
  end
  
  def check_username
    @username = params[:id]
    return fail_403 unless @username
    @user = Account.find_by_username @username
    return fail_403 unless @user
    return true
  end
  
  def fail_403
    render :text=>'403 Forbidden', :status=>403
    return false
  end
end
