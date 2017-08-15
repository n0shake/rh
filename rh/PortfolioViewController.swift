//
//  ViewController.swift
//  rh
//
//  Created by Abhishek Banthia on 8/7/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import SwiftyJSON

private enum PortfolioKeys : String {
    case DragKey = "move"
    case WatchListNibName = "WatchListPopover"
    case ErrorDefault = "Some Error"
    case JsonResultsKey = "results"
    case GroupCellIdentifier = "GroupCell"
    case WatchListGroupCellTitle = "Watchlist"
    case WatchListGroupCellIdentifier = "watchlistCell"
    case PortfolioListGroupCellTitle = "Portfolio"
    case PortfolioListGroupCellIdentifier = "stockCell"
}

class PortfolioViewController: NSViewController {
    
    @IBOutlet weak var loadingLabel: NSTextField!
    @IBOutlet weak var loadingView: NSView! {
        didSet {
            self.loadingView.wantsLayer = true
            self.loadingView.layer?.backgroundColor = NSColor.white.cgColor
            self.loadingView.isHidden = true
        }
    }

    static var portfolioCounter = 0
    
    @IBOutlet weak var shareApp: NSButton! {
        didSet {
            self.shareApp.sendAction(on: .leftMouseDown)
        }
    }
    
    
    @IBOutlet weak var mainTableview: NSTableView! {
        didSet {
            self.mainTableview.register(forDraggedTypes: [PortfolioKeys.DragKey.rawValue])
        }
    }
    @IBOutlet weak var supplementaryView: NSView! {
        didSet {
            self.supplementaryView.wantsLayer = true
            self.supplementaryView.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
    
    fileprivate var securitiesOwned = [SecurityOwned]()
    
    fileprivate var portfolios = [Security]()
    
    init() {
        super.init(nibName: PortfolioKeys.WatchListNibName.rawValue, bundle: nil)!
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchSecuritiesOwned()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    fileprivate func fetchSecuritiesOwned() {
        
        if NetworkAssistant.isConnected() == false {
            DispatchQueue.main.async {
               self.loadingView.isHidden = false
               self.loadingLabel.stringValue = "You appear to be offline."
                return
            }
        }
        
        APIManager.shared.getRequest(Endpoints.SecuritiesURL.url) { (responseJSON, error) in
            
            DispatchQueue.main.async {
                self.perform(#selector(self.hideLoadingView), with: nil, afterDelay: 5)
            }
    
            guard let data = responseJSON, error == nil else {
                // check for fundamental networking error
                print(error?.localizedDescription ?? PortfolioKeys.ErrorDefault.rawValue)
                return
            }
            
            let securities = data[PortfolioKeys.JsonResultsKey.rawValue].array
            DispatchQueue.main.async {
                for security in securities! {
                    let stock = SecurityOwned(json: security)
                    self.securitiesOwned.append(stock)
                }
                self.mainTableview.reloadData()
            }

        }
    }
    
    @objc private func hideLoadingView() {
        self.loadingLabel.stringValue = ""
        self.loadingView.isHidden = true
    }
    
    func getInstrument(withURL: String?) {
        
        APIManager.shared.getInstrument(withURL: withURL!) { (json, error) in
            
            if error == nil {
                let security = Security(json: (json?.dictionary)!)
                self.portfolios.append(security)
            }
            else {
                print(error?.localizedDescription ?? PortfolioKeys.ErrorDefault.rawValue)
            }
            
        }
    }
    
    @IBAction func showPreferences(_ sender: Any) {
        closePopover()
        let preferencesWindow = PreferencesWindowController.sharedWindow
        preferencesWindow.showWindow(self)
        preferencesWindow.window?.orderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.securitiesOwned = [SecurityOwned]()
        self.portfolios = [Security]()
        self.loadingView.isHidden = false
        self.loadingLabel.stringValue = "Refreshing..."
        self.fetchSecuritiesOwned()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MenubarTitleNeedsUpdate"), object: nil)
    }
   
    @IBAction func logoutAction(_ sender: Any) {
        let delegate = NSApplication.shared().delegate as! AppDelegate
        delegate.logout()
    }
    
    @IBAction func shareAction(_ sender: NSButton) {
        let shareText = "Put Robinhood in your menubar. Download at https://github.com/abhishekbanthia/rh/tree/master/Releases/rh.app.zip"
        let servicePicker = NSSharingServicePicker(items: [shareText])
        servicePicker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minX)
    }
        
    func closePopover() {
        let delegate = NSApplication.shared().delegate as! AppDelegate
        delegate.toggle()
    }
    
}

extension PortfolioViewController : NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.securitiesOwned.count+self.portfolios.count+2
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if row == 0 {
            let field = tableView.make(withIdentifier: PortfolioKeys.GroupCellIdentifier.rawValue, owner: tableView) as? NSTextField
            field?.stringValue = PortfolioKeys.PortfolioListGroupCellTitle.rawValue
            return field
        }
        
        if row == self.securitiesOwned.count + 1 {
            let field = tableView.make(withIdentifier: PortfolioKeys.GroupCellIdentifier.rawValue, owner: tableView) as? NSTextField
            field?.stringValue = PortfolioKeys.WatchListGroupCellTitle.rawValue
            return field
        }
        
        if row < self.securitiesOwned.count + 1 {
            let cell = tableView.make(withIdentifier: PortfolioKeys.PortfolioListGroupCellIdentifier.rawValue, owner: tableView) as? StockTableViewCell
            cell?.configure(security: self.securitiesOwned[row-1])
            return cell
        }
        
        if portfolios.count > 0 && PortfolioViewController.portfolioCounter < portfolios.count {
            let cell = tableView.make(withIdentifier: PortfolioKeys.WatchListGroupCellIdentifier.rawValue, owner: tableView) as? WatchlistTableCellView
            cell?.configure(self.portfolios[PortfolioViewController.portfolioCounter])
            PortfolioViewController.portfolioCounter += 1
            return cell
        }
        
        return nil
        
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if row == 0 || row == self.securitiesOwned.count + 1{
            return true
        }
        return false
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row == 0 || row == self.securitiesOwned.count + 1 {
            return 23
        }
        
        return tableView.rowHeight
    }
    
    // Mark: Reordering
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes([PortfolioKeys.DragKey.rawValue], owner: self)
        pboard.setData(data, forType: PortfolioKeys.DragKey.rawValue)
        return true
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        
        if row == 0 || row >= self.securitiesOwned.count + 1{
            return false
        }
        
        var destinationRow = row
        
        if destinationRow == 0 {
            return false
        }
        
        if destinationRow >= self.securitiesOwned.count+1 {
            destinationRow = destinationRow - 1
        }
        
        let pasteboard : NSPasteboard = info.draggingPasteboard()
        let data: Data = pasteboard.data(forType: PortfolioKeys.DragKey.rawValue)!
        let rowIndexes = NSKeyedUnarchiver.unarchiveObject(with: data) as! IndexSet
        print(rowIndexes.first!, destinationRow)
        let currentSecurity : SecurityOwned = self.securitiesOwned[rowIndexes.first!-1]
        self.securitiesOwned.remove(at: rowIndexes.first!-1)
        self.securitiesOwned.insert(currentSecurity, at: destinationRow-1)
        self.mainTableview.reloadData()
        
        return true
    }
    
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        return .move
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
    }
    
}

