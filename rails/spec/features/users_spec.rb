require 'rails_helper'

RSpec.describe 'Users', type: :feature do
  # JSが不要なら rack_test で十分（速い）
  # before { driven_by(:rack_test) }

  # JSやフロントの動きが必要ならこっちを有効化
  # before { driven_by(:selenium, using: :headless_chrome) }

  it 'has title' do
    visit '/users'
    # Playwright の toHaveTitle(/Myapp/) 相当
    expect(page).to have_title(/Myapp/i)
  end

  it 'gets new user link' do
    visit '/users'

    # Playwright の getByRole('link', { name: 'New User' }).click() 相当
    click_link 'New User'

    # Playwright の heading(name: 'New User') 相当
    # 見出しが h1 ならこれでOK。h2/h3でも動くように汎用セレクタで見る例も下に。
    expect(page).to have_selector('h1', text: 'New User')

    # 見出しタグが一定しないならこっちでも可
    # expect(page).to have_selector('h1, h2, [role=heading]', text: 'New User')
  end
end
