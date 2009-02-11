require 'lighthouse'
require 'basecamp'


APP_CONFIG = YAML.load_file('config/config.yml')

#Lighthouse setup
Lighthouse.account = APP_CONFIG['lighthouse']['account']
Lighthouse.token = APP_CONFIG['lighthouse']['token']
lh_proj = Lighthouse::Project.find(APP_CONFIG['lighthouse']['project'])

#Basecamp Setup
Basecamp.establish_connection!(APP_CONFIG['basecamp']['account'], APP_CONFIG['basecamp']['user'], APP_CONFIG['basecamp']['password'])
bc = Basecamp.new()

#Saved Milestones
milestones = YAML.load_file( 'config/milestones.yml' )

def get_bc_milestone(bc, ms_id)
  #TODO: Pull out Milestone instead of looping through the whole set.
  bc.milestones(APP_CONFIG['basecamp']['project']).each do |milestone|
    return milestone if milestone.id == ms_id
  end
  nil
end

milestones.each do |milestone|
  ignore = milestone[1]['ignore']
  if !ignore
    lh_ms = Lighthouse::Milestone.find(milestone[1]['lighthouse'].to_i, :params => {:project_id => APP_CONFIG['lighthouse']['project'] }) if milestone[1]['lighthouse'].to_i > 0
    bc_ms = get_bc_milestone(bc, milestone[1]['basecamp'].to_i) 
    lh_date = (lh_ms ? Date.parse(lh_ms.due_on.strftime('%Y/%m/%d')) : nil)
    bc_date = (bc_ms ? bc_ms.deadline : nil)
    if lh_ms and bc_ms
      #Make sure both id's are in the settings file
      if lh_date == bc_date
        puts "Dates Match: All OK"
      else
        #set the lighthouse due date to the basecamp date
        lh_ms.due_on = Time.utc(bc_ms.deadline.year,bc_ms.deadline.month,bc_ms.deadline.day,11,00,00)
        lh_ms.save
        puts "Dates Mismatch: NOT OK - lh_ms: #{lh_date}, bc_ms: #{bc_date} - (#{milestone[0]}) - Updated Lighthouse to: #{lh_ms.due_on}"
      end
    elsif lh_ms and !bc_ms
      #basecamp missing
      puts "Basecamp Missing Milestone - lh_ms: #{lh_date} -  (#{milestone[0]})"
    elsif !lh_ms and bc_ms
      #Lighthouse missing
      puts "Lighthouse Missing Milestone - bc_ms: #{bc_date} - (#{milestone[0]})"
    else
      puts "Something else"
    end
  end
end
