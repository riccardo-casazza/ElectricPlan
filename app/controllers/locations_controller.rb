class LocationsController < ApplicationController
  def regions
    country = Carmen::Country.coded(params[:country_code])
    return render json: [] unless country

    regions = country.subregions.map { |r| { code: r.code, name: r.name } }
    render json: regions.sort_by { |r| r[:name] }
  end

  def departments
    country = Carmen::Country.coded(params[:country_code])
    return render json: [] unless country

    region = country.subregions.coded(params[:region_code])
    return render json: [] unless region

    departments = region.subregions.map { |d| { code: d.code, name: d.name } }
    render json: departments.sort_by { |d| d[:name] }
  end
end
