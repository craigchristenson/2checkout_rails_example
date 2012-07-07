### _For a discount on 2Checkout’s monthly fees, enter promo code:  GIT2CO  during signup._

###Introduction
In this repo we show an example integration of the 2Checkout payment method
into an existing Rails 3.2.2 shopping cart application using the ActiveMerchant gem.

###Setting up the Example Application
We need an existing example application to demonstrate the integration so lets
clone the 2checkout-rails-example application.
``` sh terminal
$ git clone https://github.com/craigchristenson/2checkout_rails_example
```
This repository contains both an example before and after application so that
we can follow along with the tutorial using the
2checkout_rails_example_before app and compare the result with the
2checkout_rails_example_after app. We can start by navigating to the
2checkout_rails_example_before directory.
``` sh terminal
$ cd 2checkout_rails_example/2checkout_rails_example_before
```
From here, we run `bundle install` to install the gems from the Gemfile.
``` sh terminal
$ bundle install
```
We then need to run the migrations and seed the database.
``` sh terminal
$ rake db:migrate
$ rake db:seed
```
We can then run the example application.
``` sh terminal
$ rails s
```
View the application in your browser at
[http://localhost:3000](http://localhost:3000)

As you can see, we have an example shopping cart application that allows you
to View/Edit Products, View/Edit Orders and Buy Products. We can test the
current shopping cart functionality of the application by selecting Buy
Products and adding a couple of products to the cart.

The cart calculates the total correctly and lists the appropriate lineitems and
quantitys, but the buyer cannot pay for their order. We will correct this by adding
2Checkout as a payment method in a few simple steps with the help of the
Active Merchant gem.

###Installing Active Merchant

First, lets stop the development server in the terminal `Ctrl + C`. Now we can
add the latest version of the activemerchant gem to our Gemfile.

``` ruby Gemfile
$ gem 'activemerchant', :git => 'https://github.com/Shopify/active_merchant.git'
```

Next, we need to install the gem using the `bundle install` command in our terminal.

``` sh terminal
$ bundle install
```

The `activemerchant` gem also installs the `money` gem as a dependency which
we will use in the next section of the tutotial.

###Adding 2Checkout as a Payment Method

The first thing we will do is add the necessary gems and helpers to our environment.

``` ruby config/enviroment.rb
require File.expand_path('../application', __FILE__)

ExampleStore::Application.initialize!
require 'money'
require 'active_merchant'
require 'active_merchant/billing/integrations/action_view_helper'
ActionView::Base.send(:include,
                      ActiveMerchant::Billing::Integrations::ActionViewHelper)
```

This allows us to use the necessary helpers provided by Active Merchant in our
application. Next we will include `ActiveMerchant::Billing:Integrations` to
our carts controller.

``` ruby app/controllers/carts_controller.rb
class CartsController < ApplicationController
  include ActiveMerchant::Billing::Integrations
...
```

Now that our carts controller has access to the features provided by Active Merchant, we can
add the 2Checkout payment method to our carts view using the
`action_view_helper`.

``` ruby app/views/show.html.erb
<p id="notice"><%= notice %></p>

<h1>Shopping Cart</h1>

<table id="cart" class="table table-striped">
  <tr>
    <th>Product</th>
    <th>Qty</th>
    <th class="price">Unit Price</th>
    <th class="price">Full Price</th>
  </tr>
  <% for line_item in @cart.line_items %>
    <tr class="<%= cycle :odd, :even %>">
      <td><%=h line_item.product.name %></td>
      <td class="qty"><%= line_item.quantity %></td>
      <td class="price"><%= number_to_currency(line_item.unit_price) %></td>
      <td class="price"><%= number_to_currency(line_item.full_price) %></td>
    </tr>
  <% end %>
  <tr>
    <td class="total price" colspan="4">
      Total: <%= number_to_currency @cart.total_price %>
    </td>
  </tr>
</table>

<% payment_service_for @cart.id, '1303908',
                                   :amount => @cart.total_price,
                                   :service => :two_checkout,
                                   :credential2 => 'tango',
                                   :html => { :id => 'payment-form' } do |service| %>

  <% for line_item in @cart.line_items %>
    <% service.auto_settle :prod => line_item.product.id.to_s + ',' + line_item.quantity.to_s,
                         :price => line_item.unit_price,
                         :name => line_item.product.name,
                         :description => line_item.product.description %>
  <% end %>

  <input type=submit value=" Pay for your Order ">
<% end %>
```

Lets take a second to look at what we did here. The `payment_service_for`
Action View helper defines the payment method being used, the credentials
for the payment method and the sale details such as the order details. For 2Checkout,
we define the order identifier with the `@cart.id`, our 2Checkout account number,
the sale total with the `@cart.total_price`, `two_checkout` as the payment method,
2Checkout secret word and then we add the lineitem parameters for each lineitem
included in the current cart using the `auto_settle` method provided by Active Merchant.
This method uses the 2Checkout Third Party Cart parameters to define the lineitems. We
also add a submit button with the text "Pay for your Order" so that the buyer can click
the button to pay with 2Checkout. Lets test this and make sure we setup everything
correctly by loading up our server again and adding some products to our cart.


We now have a "Pay for your Order" button that when clicked, passes the buyer
to 2Checkout to make their payment.


###Adding support for the Passback from 2Checkout

Once the sale is processed successfully, 2Checkout passes the customer and the
sale parameters back to the approved URL that you setup on the Site Management
page in your 2Checkout account. We don't have a method yet to handle the
passback so lets go ahead and create one in our carts controller.

``` ruby app/conrollers/carts_controller.rb
class CartsController < ApplicationController
  include ActiveMerchant::Billing::Integrations

  def index
    @carts = Cart.all
  end

  def show
    @cart = current_cart
  end

  def new
    @cart = Cart.new
  end

  def edit
    @cart = Cart.find(params[:id])
  end

  def create
    @cart = Cart.new(params[:cart])
  end

  def update
    @cart = Cart.find(params[:id])
  end

  def destroy
    @cart = Cart.find(params[:id])
    @cart.destroy
  end

  def twocheckout_return
    notification = TwoCheckout::Notification.new(request.query_string,
      options = {:credential2 => "tango"})

    @cart = Cart.find(notification.item_id)

    if notification.complete?
      begin
        if notification.acknowledge
          @cart.status = 'success'
          @cart.purchased_at = Time.now
          @order = Order.create(:total => params['total'],
          :card_holder_name => params['card_holder_name'],
           :order_number => params['order_number'])
          reset_session
          redirect_to @order
        else
          @cart.status = "failed"
          render :text =>"Order Failed! MD5 Hash does not match!"
        end
        ensure
        @cart.save
      end
    end
  end
end
```

Here we specify our method name `twocheckout_return` and create a new instance of `TwoCheckout::Notification` provided by ActiveMerchant. 
Here we pass the returned parameters using `request.query_string` and specify our 2Checkout secret word
in the options. This instance maps the returned parameters and checks the MD5
Hash returned by 2Checkout. We create a new instance variable `@cart` that
identifies the buyer's cart id and update the status. If successful, we update
the cart as successful, create the order, reset the session and redirect the buyer
to their order success page. If the MD5 hash returned from 2Checkout does not match,
we set the cart status to `failed` and display an error to the buyer.

Lets go ahead and create a route for this method.

``` ruby config/routes.rb
ExampleStore::Application.routes.draw do
  resources :carts

  resources :line_items

  resources :categories

  resources :orders

  resources :products

  match '/paid'=>'carts#twocheckout_return'

  root :to => 'products#index'
end
```
Now that we have our return URL route we need to set the path as your 2Checkout
account's approved URL. Lets login to our 2Checkout account and navigate to the
Account tab and Site Management subtab. 

From here we can set our new route as the approved URL, select Header Redirect and save our changes.

Lets acid test our application with a live sale!

Start up our server _(If it's not started already.)_

``` sh terminal
$ rails s
```

Add some products to our cart and click the **Pay for your Order** button and complete the order with 2Checkout.

We now have our Rails application properly integrated with 2Checkout and are ready
to start accepting live sales!

If you have any questions or concerns, let me know. 
I will be happy to help with your application and get you up and running.
