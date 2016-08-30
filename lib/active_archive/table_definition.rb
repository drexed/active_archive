module TableDefinition

  def timestamps(*args)
    options = args.extract_options!
    options[:null] = false if options[:null].nil?

    column(:created_at, :datetime, options)
    column(:updated_at, :datetime, options)

    options[:null] = true
    column(:archived_at, :datetime, options)

    super(*args)
  end

end
