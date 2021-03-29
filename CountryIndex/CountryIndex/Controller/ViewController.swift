//
//  ViewController.swift
//  CountryIndexTask
//
//  Created by Mauricio Dias on 23/3/21.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate, UISearchResultsUpdating {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var countryArray = [Country]()
    var displayCountries : [String] = Array()
    var isSearching = false
    
    var limitItemsShown = 20
    let urlEndpoint = "https://uat-web.automic.com.au/er/public/api/countries/"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        loadDataFromJSOM(url: urlEndpoint)
    }
    
    // MARK: UpdateUI - LoadData
    func updateUITableView(){
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func loadDataFromJSOM(url endpoint: String){
        if endpoint == "" {
            performRequest(urlString: urlEndpoint)
        } else {
            performRequest(urlString: endpoint)
        }
    }
    
    func getLimitItemsShown() -> Int {
        let index = displayCountries.count
        var limit = 0
        if (index+limitItemsShown) > (countryArray.count) {
            limit = countryArray.count - index
        } else {
            limit  = index + limitItemsShown
        }
        return limit
    }
    
    func addItemsToTableView(){
        var index = displayCountries.count
        let limitItems = getLimitItemsShown()
        while index<limitItems  {
            displayCountries.append(countryArray[index].countryName)
            index+=1
        }
    }
    
    
    // MARK: Config TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.displayCountries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        cell.textLabel?.text = displayCountries[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isSearching {
            //in searching mode should not add any other data extra
            return
        }
        if indexPath.row == (displayCountries.count-1) {
            addItemsToTableView()
            self.perform(#selector(loadTableView), with: nil, afterDelay: 0.5)
        }
    }
    
    @objc func loadTableView(){
        self.tableView.reloadData()
    }
    
    
    // MARK: Perform Request URL
    func performRequest(urlString: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) {(data, response, error) in
                if error != nil {
                    print(error!)
                    return //exit
                }
                if let safeData = data {
                    self.parseJSON(countryData: safeData)
                    self.saveDataPhisically(countryData: safeData)
                }
            }
            task.resume()
        }
    }
    
    // MARK: ParseJSON data
    func parseJSON(countryData: Data){
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode([CountryJSON].self, from: countryData)
            for country in decodedData {
                countryArray.append(Country(isoCode: country.isoCode, isoCode2: country.isoCode2, countryName: country.countryName))
            }
            addItemsToTableView()
            updateUITableView()
        } catch  {
            print(error)
        }
    }

    func saveDataPhisically(countryData: Data){
        do {
            let fileURL = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("countries.json")
            let encoder = try JSONEncoder().encode(countryData)
            try encoder.write(to: fileURL)
            
        } catch {
            print("JSONSave error of \(error)")
        }
    }
    
    // MARK: Search Bar Config
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        displayCountries.removeAll()
        if searchText == "" {
            isSearching = false
            addItemsToTableView()
        } else {
            var nameWasFound = false
            for countries in countryArray {
                nameWasFound = ((countries.countryName.lowercased().contains(searchText.lowercased())) || (countries.isoCode.lowercased().contains(searchText.lowercased())))
                if nameWasFound {
                    displayCountries.append(countries.countryName)
                    isSearching = true
                }
            }
        }
        updateUITableView()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        //leave this methods to be able to use searchbar(selectedScopeButtonIndexDidChange)
    }
    
    
    
    // MARK: Scope Buttons Config
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchBar.searchTextField.text = ""
        let scopeButtonText = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        sortDataAll(scopeButtonText: scopeButtonText)
        reloadData()
    }
    
    func reloadData(){
        displayCountries.removeAll()
        addItemsToTableView()
        updateUITableView()
    }
    
    func sortDataAll(scopeButtonText: String){
        if scopeButtonText == "Descending" {
            countryArray.sort(by: {
                $0.countryName > $1.countryName
            })
        } else {
            countryArray.sort(by: {$0.countryName < $1.countryName})
        }
    }

}
