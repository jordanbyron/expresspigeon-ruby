
TEMPLATE_ID ||= 1
LIST_ID ||= 12
API_USER ||= "non@non.non"
DISABLED_LIST ||= 12

module PigeonSpecHelper
  def validate_response res, code, status, message
    res.code.should eq code
    res.status.should eq status
    if message
      (res.message =~ message).should_not be_nil
    end

  end
end