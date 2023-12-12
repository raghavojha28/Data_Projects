select * from analysis.nashville_housing_data_for_data_cleaning

-- Converting date datatype from varchar to date 

select SaleDate, CONVERT(SaleDate, Date) as SaleDateConverted
from analysis.nashville_housing_data_for_data_cleaning;

alter table analysis.nashville_housing_data_for_data_cleaning
add SaleDateConverted Date

update analysis.nashville_housing_data_for_data_cleaning
set SaleDateConverted = CONVERT(SaleDate, Date);

select * from analysis.nashville_housing_data_for_data_cleaning


-- Breaking Address into Individual Columns (Address, City, State)

select SUBSTRING(PropertyAddress, 1, locate(",", PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, locate(",", PropertyAddress) +1, length(PropertyAddress)) as City
from analysis.nashville_housing_data_for_data_cleaning


alter table analysis.nashville_housing_data_for_data_cleaning 
add SplitAddress varchar(255)

update analysis.nashville_housing_data_for_data_cleaning 
set SplitAddress = SUBSTRING(PropertyAddress, 1, locate(",", PropertyAddress) -1)

alter table analysis.nashville_housing_data_for_data_cleaning 
add SplitCity varchar(255)

update analysis.nashville_housing_data_for_data_cleaning 
set SplitCity = SUBSTRING(PropertyAddress, locate(",", PropertyAddress) +1, length(PropertyAddress))


-- Changing Y & N to Yes and No in "soldasvacant" column

select distinct SoldAsVacant, Count(SoldAsVacant)
from analysis.nashville_housing_data_for_data_cleaning
group by SoldAsVacant
order by 2


select SoldAsVacant 
, case when SoldAsVacant = "Y" then "Yes"
     when SoldAsVacant = "N" then "No"
     else SoldAsVacant 
     end
from analysis.nashville_housing_data_for_data_cleaning

update analysis.nashville_housing_data_for_data_cleaning 
set SoldAsVacant = case when SoldAsVacant = "Y" then "Yes"
     when SoldAsVacant = "N" then "No"
     else SoldAsVacant 
     end

     
-- Removing Duplicates   
                
-- Looking for rows that have duplicate values in there. 

with CTE as (
select *,
        row_number() over (
        partition by ParcelID,
                     PropertyAddress,
                     UniqueID,
                     SaleDate, 
                     SalePrice, 
                     LegalReference
                     order by UniqueID 
                     ) as row_num                     
from analysis.nashville_housing_data_for_data_cleaning )
select * from CTE
where row_num > 1
order by UniqueID



with CTE as (
select *,
        row_number() over (
        partition by ParcelID,
                     PropertyAddress,
                     UniqueID,
                     SaleDate, 
                     SalePrice, 
                     LegalReference
                     order by UniqueID 
                     ) as row_num                     
from analysis.nashville_housing_data_for_data_cleaning )
delete from CTE
where row_num > 1



-- Deleting Unused Columns 


Select *
From analysis.nashville_housing_data_for_data_cleaning 

Alter Table analysis.nashville_housing_data_for_data_cleaning 
Drop Column SaleDate, PropertyAddress



