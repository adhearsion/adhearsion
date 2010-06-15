class Module

  ##
  # In OOP, relationships between classes should be treated as *properties* of those classes. Often, in a complex OO
  # architecture, you'll end up with many relationships that intermingle in monolithic ways, blunting the effectiveness of
  # subclassing.
  #
  # For example, say you have an Automobile class which, in its constructor, instantiates a new Battery class and performs
  # some operations on it such as calling an install() method. Let's also assume the Automobile class exposes a repair()
  # method which uses a class-level method of Battery to diagnose your own instance of Battery. If the result of the
  # diagnosis shows that the Battery is bad, the Automobile will instantiate a new Battery object and replace the old battery
  # with the new one.
  #
  # Now, what if you wish to create a new Automobile derived from existing technology: a HybridAutomobile subclass. For this
  # particular HybridAutomobile class, let's simply say the only difference between it and its parent is which kind of
  # Battery it uses -- it requires its own special subclass of Battery. With Automobile's current implementation, its
  # references to which Battery it instantiates and uses are embedded in the immutable method defintions. This
  # HybridAutomobile needs to override which Battery its superclass' methods use and nothing else.
  #
  # For this reason, the Battery class which Automobile uses is semantically a property which others may want to override.
  # In OOP theory, we define overridable properties in the form of methods and override those methods in the subclasses.
  #
  # This method exposes one method which creates human-readable semantics to defining these relationships as properties. It's
  # used as follows:
  #
  # class Automobile
  #   relationship :battery => Battery
  #   relationship :chassis => Chassis
  #   # Other properties and instance methods here....
  # end
  #
  # class HybridAutomobile < Automobile
  #   relationship :battery => HybridBattery
  # end
  #
  def relationships(relationship_mapping)
    relationship_mapping.each_pair do |class_name, class_object|
      define_method(class_name) { class_object }
    end
  end

end