class CompaniesController < ApplicationController
  
  def new
    @company = Company.new
    @company.users.build
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @company}
    end
  end
  
  def register
    @company = Company.new(params[:company])
    respond_to do |format|
      if @company.save
        flash[:success] = 'Company was successfully created.'
        format.html { redirect_to(new_company_path) }        
      else
        format.html { render :action => "new" }        
      end
    end    
  end
  
end
