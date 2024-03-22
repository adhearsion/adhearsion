# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe I18n do
    describe '#locale' do
      around do |example|
        enforce_available_locales = ::I18n.enforce_available_locales
        ::I18n.enforce_available_locales = false
        example.run
        ::I18n.enforce_available_locales = enforce_available_locales
      end

      after do
        ::I18n.locale = ::I18n.default_locale
      end

      it 'returns the set I18n locale' do
        expect(described_class.locale).to eq(::I18n.default_locale)
        ::I18n.locale = :it
        expect(described_class.locale).to eq(:it)
      end
    end

    describe '#t' do
      it 'should use a default locale' do
        ssml = described_class.t(:have_many_cats)
        expect(ssml['xml:lang']).to match(/^en/)
      end

      it 'should allow overriding the locale per-request' do
        ssml = described_class.t(:have_many_cats, locale: 'it')
        expect(ssml['xml:lang']).to match(/^it/)
      end

      it 'should generate proper SSML with both audio and text fallback translations' do
        ssml = described_class.t(:have_many_cats)
        expect(ssml).to eql(RubySpeech::SSML.draw(language: 'en') do
          audio src: "file://#{Adhearsion.root}/app/assets/audio/en/have_many_cats.wav" do
            string 'I have quite a few cats'
          end
        end)
      end

      it 'should generate proper SSML with only audio (no fallback text) translations' do
        ssml = described_class.t(:my_shirt_is_white)
        expect(ssml).to eql(RubySpeech::SSML.draw(language: 'en') do
          audio src: "file://#{Adhearsion.root}/app/assets/audio/en/my_shirt_is_white.wav" do
            string ''
          end
        end)
      end

      it 'should generate proper SSML with only text (no audio) translations' do
        ssml = described_class.t(:many_people_out_today)
        expect(ssml).to eql(RubySpeech::SSML.draw(language: 'en') do
          string 'There are many people out today'
        end)
      end

      it 'should generate a path to the audio prompt based on the requested locale' do
        ssml = described_class.t(:my_shirt_is_white, locale: 'it')
        expect(ssml).to eql(RubySpeech::SSML.draw(language: 'it') do
          audio src: "file://#{Adhearsion.root}/app/assets/audio/it/la_mia_camicia_e_bianca.wav" do
            string ''
          end
        end)
      end

      it 'should fall back to a text translation if the locale structure does not break out audio vs. tts' do
        ssml = described_class.t(:seventeen, locale: 'it')
        expect(ssml).to eql(RubySpeech::SSML.draw(language: 'it') do
          string 'diciassette'
        end)
      end

      context 'with fallback disabled, requesting a translation' do
        before do
          Adhearsion.config.core.i18n.fallback = false
        end

        after do
          Adhearsion.config.core.i18n.fallback = true
        end

        it 'should generate proper SSML with only audio (no text) translations' do
          ssml = described_class.t(:my_shirt_is_white)
          expect(ssml).to eql(RubySpeech::SSML.draw(language: 'en') do
            audio src: "file://#{Adhearsion.root}/app/assets/audio/en/my_shirt_is_white.wav"
          end)
        end

        it 'should generate proper SSML with only text (no audio) translations' do
          ssml = described_class.t(:many_people_out_today)
          expect(ssml).to eql(RubySpeech::SSML.draw(language: 'en') do
            string 'There are many people out today'
          end)
        end

        it 'should generate proper SSML with only audio translations when both are supplied' do
          ssml = described_class.t(:have_many_cats)
          expect(ssml).to eql(RubySpeech::SSML.draw(language: 'en') do
            audio src: "file://#{Adhearsion.root}/app/assets/audio/en/have_many_cats.wav"
          end)
        end
      end
    end
  end
end
