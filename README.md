### _For a discount on 2Checkout’s monthly fees, enter promo code:  GIT2CO  during signup._

2Checkout Rails Integration Example
----------------------------------------

This is an example shopping cart application which demonstrates 2Checkout integration using Rails 3.2.

The example cart uses the 2Checkout integration provided by the activemerchant gem.

To get started, just clone and run bundle install.

You can then specify your seller ID (2Checkout Account Number) in the `payment_service_for` form helper in 'app/views/cart/show.html.erb'.

Your 2Checkout approved URL can be set to 'http://localhost:3000/paid' (replacing 'http://localhost:3000' with your URL)

Demo mode can be set to 'On' by specifying `ActiveMerchant::Billing::Base.mode = :test` in 'config/enviroment.rb'.
_Please note: 2Checout breaks the MD5 hash returned on demo sales by forcing the order number computed in the hash to '1'._ 