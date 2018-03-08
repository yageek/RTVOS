//
//  RecommendedVC.swift
//  RTVOS
//
//  Created by Yannick Heinrich on 08.03.18.
//  Copyright © 2018 yageek. All rights reserved.
//

import UIKit
import RTSwift
import AVKit

final class ImageDownloader {

    let imageURL: URL
    init(URL: URL) {
        self.imageURL = URL
    }
    var image: UIImage?
    var downloadFinished: Bool {
        return image != nil
    }
}

final class CollectionImageDownloader {
    var downloaders: [URL: ImageDownloader] = [:]
    var operations: [URL: Operation] = [:]
    var queue = OperationQueue()

    func downloader(forURL URL: URL) -> ImageDownloader? {
        return downloaders[URL]
    }

    func addDownloader(URL url: URL, completion: @escaping (UIImage?, Error?) -> Void) {
        downloaders[url] = ImageDownloader(URL: url)
        let operation = BlockOperation {
            do {
                // URL seems not OK

                var string = url.deletingLastPathComponent().absoluteString
                if string.hasSuffix("/") {
                    string = String(string.dropLast())
                }
                
                let data = try Data(contentsOf: URL(string: string)!)

                let image = UIImage(data: data)
                completion(image, nil)
            } catch let error {
                print("Image download error: \(error)")
                completion(nil, error)
            }
        }

        queue.addOperation(operation)

    }

    func cancelAll() {
        queue.cancelAllOperations()
    }

    func cancelDownload(URL: URL) {
        if let op = operations[URL] {
            op.cancel()
            operations.removeValue(forKey: URL)
        }
    }
}

struct Video {
    let title: String
    let imageURL: URL
    let URN: String

    init(title: String, imageURL: URL, URN: String) {
        self.title = title
        self.imageURL = imageURL
        self.URN = URN
    }

    var image: UIImage?
}

final class RecommendedVC: UICollectionViewController {

    var downloader = CollectionImageDownloader()

    var videos: [Video] = []

    let client = RTSClient(key: key, secret: secret)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: VideoCell.reuseIdentifier)

        client.getEditorialRecommendationVideoShows(bu: .rts, success: { [unowned self] (videoList) in

            let videos = videoList.list.map { Video(title: $0.title, imageURL: $0.imageUrl, URN: $0.urn)}
            DispatchQueue.main.async {
                self.videos = videos
                self.collectionView?.reloadData()
            }

        }) { (error) in

        }

        // Do any additional setup after loading the view.
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        downloader.cancelAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return videos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.reuseIdentifier, for: indexPath) as! VideoCell

        let video = videos[indexPath.row]
        // Configure the cell
        cell.titleLabel.text = video.title

        if let downloader = downloader.downloaders[video.imageURL], downloader.downloadFinished {
            cell.imageView.image = downloader.image
        } else {

            if downloader.downloader(forURL: video.imageURL) == nil {

                downloader.addDownloader(URL: video.imageURL, completion: { [unowned self] (image, error) in
                    OperationQueue.main.addOperation {

                        if let image = image, let cell = self.collectionView?.cellForItem(at: indexPath) as? VideoCell {
                            cell.imageView.image = image
                        }
                    }
                })
            }
        }

        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let video = videos[indexPath.row]
        downloader.cancelDownload(URL: video.imageURL)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let playerController = segue.destination as? AVPlayerViewController, let selected = collectionView?.indexPathsForSelectedItems?.first {
            let urn = videos[selected.row].URN

            self.client.getURN(URN: urn, success: { (url) in
                DispatchQueue.main.async {
                    let player = AVPlayer(url: url)
                    playerController.player = player
                    player.play()
                }
            }, error: { (error) in

            })

        }
    }

}

extension RecommendedVC: AVPlayerViewControllerDelegate {

}
