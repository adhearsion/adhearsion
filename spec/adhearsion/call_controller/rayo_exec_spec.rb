# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    describe RayoExec do
      include CallControllerTestHelpers

      describe '#rayo_exec' do
        it 'sends an Exec command' do
          expect_message_waiting_for_response Adhearsion::Rayo::Command::Exec.new(api: 'sofia', args: 'status')
          subject.rayo_exec('sofia', 'status')
        end

        it 'raises an exception if not on Rayo' do
          set_type = Adhearsion.config.core.type
          Adhearsion.config.core.type = :asterisk

          expect{ subject.rayo_exec('sofia', 'status') }.to raise_error(NotImplementedError)

          Adhearsion.config.core.type = set_type
        end
      end

      describe '#rayo_app' do
        it 'sends an App component' do
          #puts Adhearsion.config.core.type
          expect_component_execution Adhearsion::Rayo::Component::App.new app: 'playback', args: 'hello'
          subject.rayo_app('playback', 'hello')
        end

        it 'raises an exception if not on Rayo' do
          set_type = Adhearsion.config.core.type
          Adhearsion.config.core.type = :asterisk

          expect{ subject.rayo_app('playback', 'hello') }.to raise_error(NotImplementedError)

          Adhearsion.config.core.type = set_type
        end
      end
    end
  end
end

