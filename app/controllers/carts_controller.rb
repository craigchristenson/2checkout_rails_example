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
    notification = TwoCheckout::Notification.new(request.query_string, options = {:credential2 => "tango"})

    @cart = Cart.find(notification.item_id)

    if notification.complete?
      begin
        if notification.acknowledge
          @cart.status = 'success'
          @cart.purchased_at = Time.now
          @order = Order.create(:total => params['total'], :card_holder_name => params['card_holder_name'], :order_number => params['order_number'])
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
