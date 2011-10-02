require 'sinatra'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'ri_cal'

set :logging, :true

get '/' do
  # Seznam predmetov po programih
  erb :index
end

get '/reload' do
  urnikURL = "http://www.famnit.upr.si/sl/studentske-strani/urniki_wise/courses.php"

  parameters = {
    # 'pagename' => 'courses',
    # 'program_index' => 9,
    # 'courses_index' => 9,
    'courses_values' => 1573,
    'show_week' => 0,
    # 'with_groups' => 1,
    # 'groups_in_cells' => 1,
    # 'show_lastchange' => 0,
    # 'print_selection_details' => 1,
    # 'show_week_number' => 0,
    # 'hide_branch_code' => 1
  }
  result = Net::HTTP.post_form(URI.parse(urnikURL), parameters)
  
  doc = Nokogiri::HTML(result.body)
  
  predmet = doc.at_css('span.caption').inner_html
  
  cal = RiCal.Calendar do |cal|
    doc.css('table.data tr.data').each do |el|
      cal.event do |event|
        tds = el.css('td')
        event.summary = predmet + " - " + tds[4].inner_html + " - " + tds[5].inner_html
        event.description = tds[6].inner_html
        time = tds[2].inner_html.split('-')
        event.dtstart = DateTime.parse(tds[1].inner_html + " " + time[0])
        event.dtend = DateTime.parse(tds[1].inner_html + " " + time[1])
        event.location = tds[3].inner_html
      end
    end
  end
  cal.to_s
end