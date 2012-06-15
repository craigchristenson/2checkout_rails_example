# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
ExampleStore::Application.initialize!
require 'money'
require 'active_merchant'
require 'active_merchant/billing/integrations/action_view_helper'
ActionView::Base.send(:include,
                      ActiveMerchant::Billing::Integrations::ActionViewHelper)