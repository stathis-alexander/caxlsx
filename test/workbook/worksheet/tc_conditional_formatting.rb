# frozen_string_literal: true

require 'tc_helper'

class TestConditionalFormatting < Test::Unit::TestCase
  def setup
    p = Axlsx::Package.new
    @ws = p.workbook.add_worksheet name: "hmmm"
    @cfs = @ws.add_conditional_formatting("A1:A1", [{ type: :cellIs, dxfId: 0, priority: 1, operator: :greaterThan, formula: "0.5" }])
    @cf = @cfs.first
    @cfr = @cf.rules.first
  end

  def test_initialize_with_options
    optioned = Axlsx::ConditionalFormatting.new(sqref: "AA1:AB100", rules: [1, 2])

    assert_equal("AA1:AB100", optioned.sqref)
    assert_equal([1, 2], optioned.rules)
  end

  def test_add_as_rule
    color_scale = Axlsx::ColorScale.new do |cs|
      cs.colors.first.rgb = "FFDFDFDF"
      cs.colors.last.rgb = "FF00FF00"
      cs.value_objects.first.type = :percentile
      cs.value_objects.first.val = 5
    end

    data_bar = Axlsx::DataBar.new color: "FFFF0000"
    icon_set = Axlsx::IconSet.new iconSet: "5Rating"
    cfr = Axlsx::ConditionalFormattingRule.new({ type: :containsText, text: "TRUE",
                                                 dxfId: 0, priority: 1,
                                                 formula: 'NOT(ISERROR(SEARCH("FALSE",AB1)))',
                                                 color_scale: color_scale,
                                                 data_bar: data_bar,
                                                 icon_set: icon_set })

    assert_kind_of(Axlsx::DataBar, cfr.data_bar)
    assert_kind_of(Axlsx::IconSet, cfr.icon_set)
    assert_kind_of(Axlsx::ColorScale, cfr.color_scale)
    cfs = @ws.add_conditional_formatting("B2:B2", [cfr])
    doc = Nokogiri::XML.parse(cfs.last.to_xml_string)

    assert_equal(1, doc.xpath(".//conditionalFormatting[@sqref='B2:B2']//cfRule[@type='containsText'][@dxfId=0][@priority=1]").size)
    assert doc.xpath(".//conditionalFormatting//cfRule[@type='containsText'][@dxfId=0][@priority=1]//formula='NOT(ISERROR(SEARCH(\"FALSE\",AB1)))'")

    cfs.last.rules.last.type = :colorScale
    doc = Nokogiri::XML.parse(cfs.last.to_xml_string)

    assert_equal(2, doc.xpath(".//conditionalFormatting//cfRule//colorScale//cfvo").size)
    assert_equal(2, doc.xpath(".//conditionalFormatting//cfRule//colorScale//color").size)

    cfs.last.rules.last.type = :dataBar
    doc = Nokogiri::XML.parse(cfs.last.to_xml_string)

    assert_equal(1, doc.xpath(".//conditionalFormatting//cfRule//dataBar").size)
    assert_equal(2, doc.xpath(".//conditionalFormatting//cfRule//dataBar//cfvo").size)
    assert_equal(1, doc.xpath(".//conditionalFormatting//cfRule//dataBar//color[@rgb='FFFF0000']").size)

    cfs.last.rules.last.type = :iconSet
    doc = Nokogiri::XML.parse(cfs.last.to_xml_string)

    assert_equal(3, doc.xpath(".//conditionalFormatting//cfRule//iconSet//cfvo").size)
    assert_equal(1, doc.xpath(".//conditionalFormatting//cfRule//iconSet[@iconSet='5Rating']").size)
  end

  def test_add_as_hash
    color_scale = Axlsx::ColorScale.new do |cs|
      cs.colors.first.rgb = "FFDFDFDF"
      cs.colors.last.rgb = "FF00FF00"
      cs.value_objects.first.type = :percentile
      cs.value_objects.first.val = 5
    end

    data_bar = Axlsx::DataBar.new color: "FFFF0000"
    icon_set = Axlsx::IconSet.new iconSet: "5Rating"

    cfs = @ws.add_conditional_formatting("B2:B2", [{ type: :containsText, text: "TRUE",
                                                     dxfId: 0, priority: 1,
                                                     formula: 'NOT(ISERROR(SEARCH("FALSE",AB1)))',
                                                     color_scale: color_scale,
                                                     data_bar: data_bar,
                                                     icon_set: icon_set }])
    doc = Nokogiri::XML.parse(cfs.last.to_xml_string)

    assert_equal(1, doc.xpath(".//conditionalFormatting[@sqref='B2:B2']//cfRule[@type='containsText'][@dxfId=0][@priority=1]").size)
    assert doc.xpath(".//conditionalFormatting//cfRule[@type='containsText'][@dxfId=0][@priority=1]//formula='NOT(ISERROR(SEARCH(\"FALSE\",AB1)))'")

    cfs.last.rules.last.type = :colorScale
    doc = Nokogiri::XML.parse(cfs.last.to_xml_string)

    assert_equal(2, doc.xpath(".//conditionalFormatting//cfRule//colorScale//cfvo").size)
    assert_equal(2, doc.xpath(".//conditionalFormatting//cfRule//colorScale//color").size)

    cfs.last.rules.last.type = :dataBar
    doc = Nokogiri::XML.parse(cfs.last.to_xml_string)

    assert_equal(1, doc.xpath(".//conditionalFormatting//cfRule//dataBar").size)
    assert_equal(2, doc.xpath(".//conditionalFormatting//cfRule//dataBar//cfvo").size)
    assert_equal(1, doc.xpath(".//conditionalFormatting//cfRule//dataBar//color[@rgb='FFFF0000']").size)

    cfs.last.rules.last.type = :iconSet
    doc = Nokogiri::XML.parse(cfs.last.to_xml_string)

    assert_equal(3, doc.xpath(".//conditionalFormatting//cfRule//iconSet//cfvo").size)
    assert_equal(1, doc.xpath(".//conditionalFormatting//cfRule//iconSet[@iconSet='5Rating']").size)
  end

  def test_single_rule
    doc = Nokogiri::XML.parse(@cf.to_xml_string)

    assert_equal(1, doc.xpath(".//conditionalFormatting//cfRule[@type='cellIs'][@dxfId=0][@priority=1][@operator='greaterThan']").size)
    assert doc.xpath(".//conditionalFormatting//cfRule[@type='cellIs'][@dxfId=0][@priority=1][@operator='greaterThan']//formula='0.5'")
  end

  def test_many_options
    cf = Axlsx::ConditionalFormatting.new(sqref: "B3:B4")
    cf.add_rule({ type: :cellIs, aboveAverage: false, bottom: false, dxfId: 0,
                  equalAverage: false, priority: 2, operator: :lessThan, text: "",
                  percent: false, rank: 0, stdDev: 1, stopIfTrue: true, timePeriod: :today,
                  formula: "0.0" })
    doc = Nokogiri::XML.parse(cf.to_xml_string)

    assert_equal(1, doc.xpath(".//conditionalFormatting//cfRule[@type='cellIs'][@aboveAverage=0][@bottom=0][@dxfId=0][@equalAverage=0][@priority=2][@operator='lessThan'][@text=''][@percent=0][@rank=0][@stdDev=1][@stopIfTrue=1][@timePeriod='today']").size)
    assert doc.xpath(".//conditionalFormatting//cfRule[@type='cellIs'][@aboveAverage=0][@bottom=0][@dxfId=0][@equalAverage=0][@priority=2][@operator='lessThan'][@text=''][@percent=0][@rank=0][@stdDev=1][@stopIfTrue=1][@timePeriod='today']//formula=0.0")
  end

  def test_to_xml
    doc = Nokogiri::XML.parse(@ws.to_xml_string)

    assert_equal(1, doc.xpath("//xmlns:worksheet/xmlns:conditionalFormatting//xmlns:cfRule[@type='cellIs'][@dxfId=0][@priority=1][@operator='greaterThan']").size)
    assert doc.xpath("//xmlns:worksheet/xmlns:conditionalFormatting//xmlns:cfRule[@type='cellIs'][@dxfId=0][@priority=1][@operator='greaterThan']//xmlns:formula='0.5'")
  end

  def test_multiple_formats
    @ws.add_conditional_formatting "B3:B3", { type: :cellIs, dxfId: 0, priority: 1, operator: :greaterThan, formula: "1" }
    doc = Nokogiri::XML.parse(@ws.to_xml_string)

    assert doc.xpath("//xmlns:worksheet/xmlns:conditionalFormatting//xmlns:cfRule[@type='cellIs'][@dxfId=0][@priority=1][@operator='greaterThan']//xmlns:formula='1'")
    assert doc.xpath("//xmlns:worksheet/xmlns:conditionalFormatting//xmlns:cfRule[@type='cellIs'][@dxfId=0][@priority=1][@operator='greaterThan']//xmlns:formula='0.5'")
  end

  def test_multiple_formulas
    @ws.add_conditional_formatting "B3:B3", { type: :cellIs, dxfId: 0, priority: 1, operator: :between, formula: ["1 <> 2", "5"] }
    doc = Nokogiri::XML.parse(@ws.to_xml_string)

    assert doc.xpath("//xmlns:worksheet/xmlns:conditionalFormatting//xmlns:cfRule[@type='cellIs'][@dxfId=0][@priority=1][@operator='between']//xmlns:formula='1 <> 2'")
    assert doc.xpath("//xmlns:worksheet/xmlns:conditionalFormatting//xmlns:cfRule[@type='cellIs'][@dxfId=0][@priority=1][@operator='between']//xmlns:formula='5'")
  end

  def test_sqref
    assert_raise(ArgumentError) { @cf.sqref = 10 }
    assert_nothing_raised { @cf.sqref = "A1:A1" }
    assert_equal("A1:A1", @cf.sqref)
  end

  def test_type
    assert_raise(ArgumentError) { @cfr.type = "illegal" }
    assert_nothing_raised { @cfr.type = :containsBlanks }
    assert_equal(:containsBlanks, @cfr.type)
  end

  def test_above_average
    assert_raise(ArgumentError) { @cfr.aboveAverage = "illegal" }
    assert_nothing_raised { @cfr.aboveAverage = true }
    assert(@cfr.aboveAverage)
  end

  def test_equal_average
    assert_raise(ArgumentError) { @cfr.equalAverage = "illegal" }
    assert_nothing_raised { @cfr.equalAverage = true }
    assert(@cfr.equalAverage)
  end

  def test_bottom
    assert_raise(ArgumentError) { @cfr.bottom = "illegal" }
    assert_nothing_raised { @cfr.bottom = true }
    assert(@cfr.bottom)
  end

  def test_operator
    assert_raise(ArgumentError) { @cfr.operator = "cellIs" }
    assert_nothing_raised { @cfr.operator = :notBetween }
    assert_equal(:notBetween, @cfr.operator)
  end

  def test_dxf_id
    assert_raise(ArgumentError) { @cfr.dxfId = "illegal" }
    assert_nothing_raised { @cfr.dxfId = 1 }
    assert_equal(1, @cfr.dxfId)
  end

  def test_priority
    assert_raise(ArgumentError) { @cfr.priority = -1.0 }
    assert_nothing_raised { @cfr.priority = 1 }
    assert_equal(1, @cfr.priority)
  end

  def test_text
    assert_raise(ArgumentError) { @cfr.text = 1.0 }
    assert_nothing_raised { @cfr.text = "testing" }
    assert_equal("testing", @cfr.text)
  end

  def test_percent
    assert_raise(ArgumentError) { @cfr.percent = "10%" } # WRONG!
    assert_nothing_raised { @cfr.percent = true }
    assert(@cfr.percent)
  end

  def test_rank
    assert_raise(ArgumentError) { @cfr.rank = -1 }
    assert_nothing_raised { @cfr.rank = 1 }
    assert_equal(1, @cfr.rank)
  end

  def test_std_dev
    assert_raise(ArgumentError) { @cfr.stdDev = -1 }
    assert_nothing_raised { @cfr.stdDev = 1 }
    assert_equal(1, @cfr.stdDev)
  end

  def test_stop_if_true
    assert_raise(ArgumentError) { @cfr.stopIfTrue = "illegal" }
    assert_nothing_raised { @cfr.stopIfTrue = false }
    refute(@cfr.stopIfTrue)
  end

  def test_time_period
    assert_raise(ArgumentError) { @cfr.timePeriod = "illegal" }
    assert_nothing_raised { @cfr.timePeriod = :today }
    assert_equal(:today, @cfr.timePeriod)
  end
end
