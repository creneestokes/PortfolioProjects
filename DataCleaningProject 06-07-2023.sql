/*
Cleaning Data in SQL Queries
*/

Select *
From [SQL Tutorial].dbo.NashvilleHousing

--Standardize Date Format
Select SaleDate
From [SQL Tutorial].dbo.NashvilleHousing

Select SaleDate, CONVERT(Date,SaleDate)
From [SQL Tutorial].dbo.NashvilleHousing

Update NashvilleHousing
Set SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
Set SaleDateConverted = CONVERT(Date,SaleDate)

--Populate Property Address

Select *
From [SQL Tutorial].dbo.NashvilleHousing
--where PropertyAddress is null
order by ParcelID

	Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.propertyaddress, b.PropertyAddress)
	From [SQL Tutorial].dbo.NashvilleHousing a
	JOIN [SQL Tutorial].dbo.NashvilleHousing b
		on a.parcelID = b.ParcelID
		and a.[uniqueID] <> b.[uniqueID]
	Where a.PropertyAddress is null

update a
SET propertyaddress = ISNULL(a.propertyaddress, b.PropertyAddress)
From [SQL Tutorial].dbo.NashvilleHousing a
JOIN [SQL Tutorial].dbo.NashvilleHousing b
	on a.parcelID = b.ParcelID
	and a.[uniqueID] <> b.[uniqueID]
Where a.PropertyAddress is null

---breaking out Address into Individual Columns (Address, City, State)

select propertyaddress, streetaddress, city
from [SQL Tutorial].dbo.NashvilleHousing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, (CHARINDEX(',', PropertyAddress)+2), Len(PropertyAddress)) as City
from [SQL Tutorial].dbo.NashvilleHousing


ALTER TABLE NashvilleHousing
Add StreetAddress varchar(255);


Update NashvilleHousing
Set StreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
Add City varchar(255)

Update NashvilleHousing
Set City = SUBSTRING(PropertyAddress, (CHARINDEX(',', PropertyAddress)+2), Len(PropertyAddress))

--now the owner address

select 
parsename(REPLACE(OwnerAddress,',','.'),3) as OwnerState,
parsename(REPLACE(OwnerAddress,',','.'),2) as OwnerCity,
parsename(REPLACE(OwnerAddress,',','.'),1) as OwnerStreetAddress
from [SQL Tutorial].dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnerState varchar(255),
	OwnerCity varchar(255),
	SplitOwnerAddress varchar(255);

Update NashvilleHousing
Set OwnerState = parsename(REPLACE(OwnerAddress,',','.'),1),
	OwnerCity = parsename(REPLACE(OwnerAddress,',','.'),2),
	SplitOwnerAddress = parsename(REPLACE(OwnerAddress,',','.'),3);

---Change y and n to yes and no in "Sold as Vacant" field

Select Distinct(SoldasVacant), Count(SoldasVacant)
from [SQL Tutorial].dbo.NashvilleHousing
Group by SoldAsVacant
order by 2

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
from [SQL Tutorial].dbo.NashvilleHousing

Update NashvilleHousing
Set SoldAsVacant=CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

---Remove Duplicates
---for practice purposes, will pretend like "uniqueID" column is not there

With RowNumCTE as(
select *,
	ROW_Number() OVER (
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
From [SQL Tutorial].dbo.NashvilleHousing
--Order by ParcelID
)
SELECT *
From RowNumCTE
where row_num>1
DELETE
From RowNumCTE
where row_num>1


--get rid of unused columns such as columne with concatenated address that we separated

SELECT *
FROM [SQL Tutorial].DBO.NashvilleHousing

alter table [SQL Tutorial].DBO.NashvilleHousing
DROP Column OwnerAddress, taxDistrict, PropertyAddress

alter table [SQL Tutorial].DBO.NashvilleHousing
DROP Column SaleDate