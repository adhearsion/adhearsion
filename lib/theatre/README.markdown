Theatre
=======

Present status: stable

A library for choreographing a dynamic pool of hierarchically organized actors. This was originally extracted from the [Adhearsion](http://adhearsion.com) framework by Jay Phillips.

In the Adhearsion framework, it was necessary to develop an internal message-passing system that could work either synchronously or asynchronously. This is used by the framework itself and for framework extensions (called _components_) to talk with each other. The source of the events is completely undefined -- events could originate from within the framework out outside the framework. For example, a Message Queue such as [Stomp](http://stomp.codehaus.org) can wire incoming events into Theatre and catch events going to a particular destination so it can proxy them out to the server.

Motivations and Design Decisions
--------------------------------

* Must maintain Ruby 1.8 and JRuby compatibility
* Must be Thread-safe
* Must provide some level of transparency into the events going through it
* Must be dynamic enough to reallocate the number of triggerrs based on load
* Must help facilitate test-driven development of Actor functionality
* Must allow external persistence in case of a crash

Example
-------

Below is an example taken from Adhearsion for executing framework-level callbacks. Note: the framework treats this callback synchronously.

    events.framework.asterisk.before_call.each do |event|
      # Pull headers from event and respond to it here.
    end

Below is an example of integration with [Stomp](http://stomp.codehaus.org/), a simple yet robust open-protocol message queue.

    events.stomp.new_call.each do |event|
      # Handle all events from the Stomp MQ server whose name is "new_call" (the String)
    end

This will filter all events whose name is "new_call" and yield the Stomp::Message to the block.

Framework terminology
--------------------

Below are definitions of terms I use in Theatre. See the respective links for more information.

* **callback**: This is the block given to the `each` method which triggers events coming in.
* **payload**: This is the "message" sent to the Theatre and is what will ultimately be yielded to the callback
* **[Actor](http://en.wikipedia.org/wiki/Actor_model)**: This refers to concurrent responders to events in a concurrent system.

Synchronous vs. Asynchronous
----------------------------

With Theatre, all events are asynchronous with the optional ability to synchronously block until the event is scheduled, triggered, and has returned. If you wish to synchronously trigger the event, simple call `wait` on an `Invocation` object returned from `trigger` and then check the `Invocation#current_state` property for `:success` or `:error`. Optionally the `Invocation#success?` and `Invocation#error?` methods also provide more intuitive access to the finished state. If the event finished with `:success`, you may retrieve the returned value of the event Proc by calling `Invocation#returned_value`. If the event finished with `:error`, you may get the Exception with `Invocation#error`.

Because many callbacks can be registered for a particular namespace, each needing its own Invocation object, the `Theatre#trigger` method returns an Array of Invocation objects.

    # We'll assume only one callback is registered and call #first on the Array of Invocations returned by #trigger
    invocation = my_theatre.trigger("your/namespace/here", YourSpecialClass.new("this can be anything")).first
    invocation.wait
    raise invocation.error if invocation.error?
    log "Actor finished with return value #{invocation.returned_value}"

Ruby 1.8 vs. Ruby 1.9 vs. JRuby
-------------------------------

Theatre was created for Ruby 1.8 because no good Actor system existed on Ruby 1.8 that met Adhearsion's needs (e.g. hierarchal with synchronous and asynchronous modes. If you wish to achieve real processor-level concurrency, use JRuby.

Presently Ruby 1.9 compatibility is not a priority but patches for compatibility will be accepted, as long as they preserve compatibility with both MRI and JRuby.
