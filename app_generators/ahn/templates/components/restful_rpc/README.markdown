Adhearsion RESTful RPC Component
================================

This is a component for people want to integrate their telephony systems with non-Ruby systems. When enabled, this component
will start up a HTTP server within the Adhearsion process and accept POST requests to invoke Ruby methods shared in the
`methods_for(:rpc)` context.

Protocol Notes
--------------

When POSTing your data to.