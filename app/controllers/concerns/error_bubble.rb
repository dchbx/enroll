# frozen_string_literal: true

module ErrorBubble
  def add_document_errors_to_dependent(dependent, document)
    if document.is_a? Array
      dependent.errors.add(document.first, document.last)
    elsif document
      document.errors.each do |k, v|
        dependent.errors.add(k, v)
      end
    end
  end

  def add_document_errors_to_consumer_role(consumer_role, document)
    if document.is_a? Array
      consumer_role.person.errors.add(document.first, document.last)
    elsif document
      document.errors.each do |k, v|
        consumer_role.person.errors.add(k, v)
      end
    end
  end

  def bubble_consumer_role_errors_by_person(person)
    if person.errors.key?(:consumer_role)
      person.consumer_role.errors.each do |k, v|
        person.errors.add(k, v)
      end
      if person.consumer_role.errors.key?(:vlp_documents)
        person.consumer_role.vlp_documents.select{|v| v.errors.any?}.each do |vlp|
          vlp.errors.each do |k, v|
            person.errors.add("#{vlp.subject}: #{k}", v)
          end
        end
        person.errors.delete(:vlp_documents)
      end
      person.errors.delete(:consumer_role)
    end
  end

  def bubble_address_errors_by_person(person)
    addresses = person.addresses.select {|a| has_any_address_fields_present?(a) && !a.valid?}
    if person.errors.key?(:addresses) && addresses.present?
      addresses.each do |address|
        address.errors.each do |k, v|
          person.errors.add("#{address.kind} address: #{k}", v)
        end
      end
      person.errors.delete(:addresses)
    end
  end

  def has_any_address_fields_present?(address)
    address.address_1.present? || address.city.present? || address.state.present? || address.zip.present?
  end
end
