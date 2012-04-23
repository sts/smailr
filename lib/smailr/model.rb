module Smailr
    module Model

        class Domain < Sequel::Model
            one_to_many :mailboxes
        end


        class Mailbox < Sequel::Model
            many_to_one :domain
            one_to_many :aliases

            def password=(clear)
                self[:password] = Digest::SHA1.hexdigest(clear)
            end
        end


        class Alias < Sequel::Model
            many_to_one :mailbox
        end

    end
end
