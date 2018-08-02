module ResqueSpec
  class << self
    def run!(queue_name)
      queues = ResqueSpec.queues.dup
      ResqueSpec.queues.clear
      queues[queue_name].each do |hash|
        hash[:class].constantize.perform(*hash[:args])
      end
    end
  end
end
