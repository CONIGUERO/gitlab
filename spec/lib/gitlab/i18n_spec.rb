# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::I18n do
  let(:user) { create(:user, preferred_language: :es) }

  describe '.selectable_locales' do
    it 'does not return languages with low translation levels', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/329723' do
      stub_const(
        'Gitlab::I18n::TRANSLATION_LEVELS',
        'pt_BR' => 0,
        'en' => 100,
        'es' => 65
      )

      expect(described_class.selectable_locales).to eq({
        'en' => 'English',
        'es' => 'Spanish - español'
      })
    end
  end

  describe '.locale=' do
    after do
      described_class.use_default_locale
    end

    it 'sets the locale based on current user preferred language' do
      described_class.locale = user.preferred_language

      expect(FastGettext.locale).to eq('es')
      expect(::I18n.locale).to eq(:es)
    end
  end

  describe '.use_default_locale' do
    it 'resets the locale to the default language' do
      described_class.locale = user.preferred_language

      described_class.use_default_locale

      expect(FastGettext.locale).to eq('en')
      expect(::I18n.locale).to eq(:en)
    end
  end
end
