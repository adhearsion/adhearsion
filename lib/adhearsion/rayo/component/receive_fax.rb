# encoding: utf-8

module Adhearsion
  module Rayo
    module Component
      class ReceiveFax < ComponentNode
        register :receivefax, :fax

        class Fax < RayoNode
          register :fax, :fax_complete

          attribute :url, String
          attribute :resolution, String
          attribute :pages, Integer
          attribute :size, Integer
        end

        class Complete
          class Finish < Event::Complete::Reason
            register :finish, :fax_complete
          end
        end
      end
    end
  end
end
