require 'set'

module SicConcern

  def generate_sic_array
    ## Deleted in favor of more efficient method -- brianweiner 8/15
    generate_nodes
  end

  private

  def generate_nodes
    nodes = Set.new
    groupedNodes = Set.new

    ## Sic Codes are organized by 4 descending categories
    ## Division label
    ##  Major Group label
    ##    Industry Group label
    ##      Sic Code Label

    ## JS Tree expects an array of node elements with parent nodes having a 'node' attribute pointing towards the children

    SicCode.all.each do |sic_code|
      ## We iterate once through all SicCodes and do an initial sort
      nodes.add({
          id: [:division, sic_code.division_code],
          text: sic_code.division_label.strip,
          selectable: false
        })
      nodes.add({
          id: [:major_group, sic_code.major_group_code],
          text: sic_code.major_group_label.strip,
          selectable: false,
          parent: [:division, sic_code.division_code]
        })
      nodes.add({
          id: [:industry_group, sic_code.industry_group_code],
          text: sic_code.industry_group_label.strip,
          selectable: false,
          parent: [:major_group, sic_code.major_group_code]
        })

      ## Lowest level nodes are selectable
      nodes.add({
          id: [:sic_code, sic_code.sic_code],
          text: sic_code.sic_label.strip + " - " + sic_code.sic_code,
          selectable: true,
          sic_code: sic_code.sic_code,
          parent: [:industry_group, sic_code.industry_group_code]
        })
    end

    parentsAndChildren = Hash.new do |hash, key|
      hash[key] = Array.new
    end
    rootNodes = []

    nodes.each do |node|
      ## Iterate through the partially grouped nodes
      unless node.has_key?(:parent)
        ## If node has no parents it is a root node
        rootNodes << node
      else
        parentsAndChildren[node[:parent]] << node
      end
    end

    nodes.each do |node|
      ## Iterate through the partially grouped nodes a final time
      nodeChildren = parentsAndChildren[node[:id]]
      if nodeChildren.any?
        ## If there are children, assign to node's nodes key
        node[:nodes] = nodeChildren
      end
    end

    ## Return the root nodes with correct keys
    rootNodes
  end

  ### Deleted in favor of more efficient method -- brianweiner 8/15
end
