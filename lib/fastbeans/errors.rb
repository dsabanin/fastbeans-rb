module Fastbeans

  class Exception < StandardError
    attr_accessor :orig_exc
  end

  class RemoteCallFailed < Fastbeans::Exception; end
  class RemoteException < Fastbeans::Exception; end
  class RemoteConnectionFailed  < Fastbeans::Exception; end
  class RemoteConnectionDead  < Fastbeans::Exception; end

end
