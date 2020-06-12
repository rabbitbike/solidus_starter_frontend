# frozen_string_literal: true

require 'spec_helper'

describe 'Address', type: :system, inaccessible: true do
  let!(:product) { create(:product, name: "RoR Mug") }
  let!(:order) { create(:order_with_totals, state: 'cart') }

  stub_authorization!

  before do
    visit spree.root_path

    click_link 'RoR Mug'
    click_button 'add-to-cart-button'

    address = 'order_bill_address_attributes'
    @state_select_css = "##{address}_state_id"
    @state_name_css = "##{address}_state_name"
  end

  context 'country requires state', js: true do
    let!(:canada) { create(:country, name: 'Canada', states_required: true, iso: 'CA') }
    let!(:uk) { create(:country, name: 'United Kingdom', states_required: true, iso: 'GB') }

    before { stub_spree_preferences(default_country_iso: uk.iso) }

    context 'but has no state' do
      it 'shows the state input field' do
        click_button 'Checkout'

        within('#billing') do
          select canada.name, from: 'Country'
          expect(page).to have_no_css(@state_select_css)
          expect(page).to have_css("#{@state_name_css}.required")
        end
      end
    end

    context 'and has state' do
      before { create(:state, name: 'Ontario', country: canada) }

      it 'shows the state collection selection' do
        click_button 'Checkout'

        within('#billing') do
          select canada.name, from: 'Country'
          expect(page).to have_no_css(@state_name_css)
          expect(page).to have_css("#{@state_select_css}.required")
        end
      end
    end

    context 'user changes to country without states required' do
      let!(:france) { create(:country, name: 'France', states_required: false, iso: 'FR') }

      it 'clears the state name' do
        click_button 'Checkout'
        within('#billing') do
          select canada.name, from: 'Country'

          page.find(@state_name_css).set('Toscana')

          select france.name, from: 'Country'

          expect(page).to have_no_css(@state_name_css)
          expect(page).to have_no_css(@state_select_css)
        end
      end
    end
  end

  context 'country does not require state', js: true do
    let!(:france) { create(:country, name: 'France', states_required: false, iso: 'FR') }

    it 'shows a disabled state input field' do
      click_button 'Checkout'

      within('#billing') do
        select france.name, from: 'Country'

        expect(page).to have_no_css(@state_name_css)
        expect(page).to have_css("#{@state_select_css}[disabled]", visible: false)
      end
    end
  end
end