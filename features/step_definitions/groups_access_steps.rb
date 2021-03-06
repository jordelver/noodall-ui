Then /^I should be able to set the permissions on that content$/ do
  fill_in "Update", :with => "Them, Us, Things"
  fill_in "Delete", :with => "Us, Things, Stuff"
  fill_in "Publish", :with => "Us, Stuff"
  fill_in "View", :with => "Us, Stuff"
  click_button "Publish"
  @_content.reload
  @_content.updatable_groups.should == ['them', 'us', 'things']
  @_content.destroyable_groups.should == ['us', 'things', 'stuff']
  @_content.publishable_groups.should == ['us', 'stuff']
  @_content.viewable_groups.should == ['us', 'stuff']
end

Given(/^content's ([^\"]*) is set to "([^\"]*)" and "([^\"]*)"$/) do |permission, group1, group2|
  @_content = Factory(:page_a, "#{permission.downcase.gsub(/e$/,'')}able_groups" => [group1, group2], :publish => true)
end

Then(/^only users in the "([^\"]*)" and "([^\"]*)" should be able to ([^\"]*) content$/) do |group1, group2, actions|
  [group1, group2].each do |group|
    Given %{I am signed in as a #{group}}
    actions.split(', ').each do |action|
      case action
      when "Update"
        visit noodall_admin_node_path(@_content)
        click_button "Draft"
      when "create children of"
        visit noodall_admin_node_nodes_path(@_content)
        within(".choices") { click_link "New" }
        click_button "Create"
      when "Delete"
        visit noodall_admin_nodes_path
        within("tr:contains('#{@_content.title}')") { click_link "Delete" }
        # REcreate for the next run
        @_content = Factory(:page_a, "destroyable_groups" => [group1, group2])
      when "Publish"
        visit noodall_admin_node_path(@_content)
        begin
          click_button "Publish"
        rescue Capybara::ElementNotFound => e
          raise Canable::Transgression # Raise this if we can't find the button
        end
      when "View"
        # Create a home page so there is something to redirect to
        Factory(:home, :title => 'Home', :publish => true, :body => "Hello this is home")
        visit node_path(@_content)
      end
    end
    Then %{I sign out} #Neeed to do this or remeber cookie gets in the way
  end
end

Then(/^users not in the "([^\"]*)" and "([^\"]*)" should not be able to ([^\"]*) content$/) do |group1, group2, action|
  Given %{I am signed in as a nogood}
  case action
  when "Update"
    visit noodall_admin_node_path(@_content)
    page.should have_content("You do not have permission to do that")
  when "create children of"
    visit noodall_admin_node_nodes_path(@_content)
    within(".choices") { click_link "New" }
    page.should have_content("You do not have permission to do that")
  when "Delete"
    visit noodall_admin_nodes_path
    within("tr:contains('#{@_content.title}')") { click_link "Delete" }
    page.should have_content("You do not have permission to do that")
  when "Publish"
    visit noodall_admin_node_path(@_content)
    lambda { click_button "Publish" }.should raise_error(Capybara::ElementNotFound)
  when "View"
    visit node_path(@_content)
    page.should have_content("You do not have permission to do that")
  end
end

Given /^content exists with permissions set$/ do
  @_content = Factory(:page_a, :updatable_groups => ['Dudes'], :destroyable_groups => ['Webbies', 'Dudes'], :publishable_groups => ['Dudes'] )
end

When /^a child of that content is created$/ do
  Given %{I am signed in as a website administrator}
  visit noodall_admin_node_nodes_path(@_content)
  within(".choices") { click_link "New" }
  fill_in "Title", :with => "Permeable Content"
  choose("Page A")
  click_button "Create"
end

Then(/^by default the child should have the same permissions as it's parent$/) do
  page.should have_css("input#node_updatable_groups_list") do |input|
    input.should have_xpath("@value") do |value|
      value.should contain("Dudes")
    end
  end
  page.should have_css("input#node_destroyable_groups_list") do |input|
    input.should have_xpath("@value") do |value|
      value.should contain("Webbies, Dudes")
    end
  end
  page.should have_css("input#node_publishable_groups_list") do |input|
    input.should have_xpath("@value") do |value|
      value.should contain("Dudes")
    end
  end
end

Then /^I should be able to carry out all actions regardless of group permissions$/ do
  Given %{content exists with permissions set}
  visit noodall_admin_node_path(@_content)
  click_button "Draft"
  visit noodall_admin_node_nodes_path(@_content)
  within(".choices") { click_link "New" }
  click_button "Create"
  visit noodall_admin_node_path(@_content)
  click_button "Publish"
  visit noodall_admin_nodes_path
  within("tr:contains('#{@_content.title}')") { click_link "Delete" }
end

Then /^I sign out$/ do
  # express the regexp above with the code you wish you had
end

Given /^the system has editor groups set to 'editor'$/ do
  User.editor_groups = ['editor']
end

Then /^a user not in the group editor will no be able to edit any content$/ do
  Factory(:home, :title => 'Home', :publish => true)
  Given %{I am signed in as a nogood}
  visit noodall_admin_nodes_path
  page.should have_content("You do not have permission to do that")
end
