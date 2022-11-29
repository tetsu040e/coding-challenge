class Plan < ApplicationRecord
  has_many :basic_prices
  has_many :unit_prices, -> { order('lower_usage_limit') }

  def calc_total_price(ampere:, amount:)
    basic_price = calc_basic_price(ampere: ampere.to_f)
    return nil if basic_price.nil?

    pay_per_use_price = calc_pay_per_use_price(amount: amount.to_f)
    return nil if pay_per_use_price.nil?

    return basic_price + pay_per_use_price
  end

  def calc_basic_price(ampere:)
    if self.basic_prices.present?
      row = self.basic_prices.select{ |basic_price| basic_price.ampere == ampere }.first
    else
      row = self.basic_prices.find_by(ampere: ampere)
    end

    return row.present? ? row.price : nil
  end

  def calc_pay_per_use_price(amount:)
    price = 0

    self.unit_prices.each do |unit_price|
      break if amount < unit_price.lower_usage_limit

      if unit_price.upper_usage_limit.nil? || amount < unit_price.upper_usage_limit
        price += (amount - unit_price.lower_usage_limit) * unit_price.price
      else
        price += (unit_price.upper_usage_limit - unit_price.lower_usage_limit) * unit_price.price
      end
    end

    return price
  end
end