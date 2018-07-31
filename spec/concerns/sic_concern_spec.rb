require 'rails_helper'
require 'sic_concern'
class SicConverter
  extend SicConcern
end

describe SicConverter do
  let!(:industry_code) { instance_double(SicCode,
                                division_code: 'A',
                                division_label: 'Industry',
                                major_group_code: '10',
                                major_group_label: 'Machinery',
                                industry_group_code: '101',
                                industry_group_label: 'Manufacturing',
                                sic_code: '1010',
                                sic_label: 'Heavy Construction Machinery Manufacturing'
                          )}
  let!(:another_industry_code) { instance_double(SicCode,
                                        division_code: 'A',
                                        division_label: 'Industry',
                                        major_group_code: '10',
                                        major_group_label: 'Machinery',
                                        industry_group_code: '105',
                                        industry_group_label: 'Repair',
                                        sic_code: '1055',
                                        sic_label: 'Heavy Construction Machinery Repair'
                              )}
  let!(:agriculture_code) { instance_double(SicCode,
                                    division_code: 'B',
                                    division_label: 'Agriculture',
                                    major_group_code: '20',
                                    major_group_label: 'Machinery',
                                    industry_group_code: '201',
                                    industry_group_label: 'Wheat Harvesting',
                                    sic_code: '2010',
                                    sic_label: 'Wheat Production'
                            )}
  let!(:services_code) { instance_double(SicCode,
                                division_code: 'C',
                                division_label: 'Services',
                                major_group_code: '30',
                                major_group_label: 'Software',
                                industry_group_code: '305',
                                industry_group_label: 'Custom Software Development',
                                sic_code: '3055',
                                sic_label: 'Custom Software Development Consulting'
                        )}

  let!(:result) { [
  {
    id: [:division, industry_code.division_code],
    text: industry_code.division_label,
    selectable: false,
      nodes: [
        {
          id: [:major_group, industry_code.major_group_code],
          text: industry_code.major_group_label,
          selectable: false,
          parent: [:division, industry_code.division_code],
          nodes: [
            {
              id: [:industry_group, industry_code.industry_group_code],
              text: industry_code.industry_group_label,
              selectable: false,
              parent: [:major_group, industry_code.major_group_code],
              nodes: [
                {
                  id: [:sic_code, industry_code.sic_code],
                  text: "#{industry_code.sic_label} - #{industry_code.sic_code}",
                  selectable: true,
                  sic_code: industry_code.sic_code,
                  parent: [:industry_group, industry_code.industry_group_code]
                }
              ]
            },
            {
              id: [:industry_group, another_industry_code.industry_group_code],
              text: another_industry_code.industry_group_label,
              selectable: false,
              parent: [:major_group, another_industry_code.major_group_code],
              nodes: [
                {
                  id: [:sic_code, another_industry_code.sic_code],
                  text: "#{another_industry_code.sic_label} - #{another_industry_code.sic_code}",
                  selectable: true,
                  sic_code: another_industry_code.sic_code,
                  parent: [:industry_group, another_industry_code.industry_group_code]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      id: [:division, agriculture_code.division_code],
      text: agriculture_code.division_label,
      selectable: false,
      nodes: [
        id: [:major_group, agriculture_code.major_group_code],
        text: agriculture_code.major_group_label,
        selectable: false,
        parent: [:division, agriculture_code.division_code],
        nodes: [
          {
            id: [:industry_group, agriculture_code.industry_group_code],
            text: agriculture_code.industry_group_label,
            selectable: false,
            parent: [:major_group, agriculture_code.major_group_code],
            nodes: [
                {
                  text: "#{agriculture_code.sic_label} - #{agriculture_code.sic_code}",
                  id: [:sic_code, agriculture_code.sic_code],
                  sic_code: agriculture_code.sic_code,
                  parent: [:industry_group, agriculture_code.industry_group_code],
                  selectable: true
                }
              ]
          }
        ]
      ]
    },
    {
      id: [:division, services_code.division_code],
      text: services_code.division_label,
      selectable: false,
      nodes: [
        {
          id: [:major_group, services_code.major_group_code],
          text: services_code.major_group_label,
          selectable: false,
          parent: [:division, services_code.division_code],
          nodes: [
            {
              id: [:industry_group, services_code.industry_group_code],
              text: services_code.industry_group_label,
              selectable: false,
              parent: [:major_group, services_code.major_group_code],
              nodes: [
                {
                  text: "#{services_code.sic_label} - #{services_code.sic_code}",
                  id: [:sic_code, services_code.sic_code],
                  parent: [:industry_group, services_code.industry_group_code],
                  sic_code: services_code.sic_code,
                  selectable: true
                }
              ]
            }
          ]
        }
      ]
    }
  ]}

  before do
    allow(SicCode).to receive(:all).and_return([industry_code, another_industry_code, agriculture_code, services_code])
  end

  it "returns a nested object" do
    expect(SicConverter.generate_sic_array).to eq(result)
  end
end
