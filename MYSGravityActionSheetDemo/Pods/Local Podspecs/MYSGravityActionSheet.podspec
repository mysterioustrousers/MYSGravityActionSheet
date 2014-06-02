Pod::Spec.new do |s|

  s.name         = "MYSGravityActionSheet"
  s.version      = "0.0.1"
  s.summary      = "An action sheet that uses UIKit Dynamics to present buttons in a playful, interesting way."

  s.description  = <<-DESC
                   A longer description of MYSGravityActionSheet in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC
  s.dependency 'PREBorderView', "~> 1.0" 
  s.homepage     = "https://github.com/mysterioustrousers/MYSGravityActionSheet"
  s.license      = "MIT"
  s.author             = { "Dan Willoughby" => "amozoss@gmail.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "http://EXAMPLE/MYSGravityActionSheet.git", :tag => "0.0.1" }
  s.source       =  {
	  :git => "https://github.com/mysterioustrousers/MYSGravityActionSheet.git",
	  :tag => "#{s.version}",
  }
  s.source_files  = "MYSGravityActionSheet", "MYSGravityActionSheet/**/*.{h,m}"
  s.requires_arc = true
end
